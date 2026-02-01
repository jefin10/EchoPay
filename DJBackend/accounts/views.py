from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings
import random
from decimal import Decimal
from rest_framework.decorators import api_view
from .models import User, OTP
from .models import UserAccount, Transaction, MoneyRequest
# Create your views here.

@api_view(['GET'])
def send_otp(request):
    """Generate and store OTP in database"""
    phone = request.GET.get("phone")
    
    if not phone:
        return JsonResponse({"status": "error", "message": "Phone number required"}, status=400)
    
    # Generate 6-digit OTP
    otp_code = str(random.randint(100000, 999999))
    
    # Delete old OTPs for this phone number
    OTP.objects.filter(phoneNumber=phone).delete()
    
    # Create new OTP entry
    otp_entry = OTP.objects.create(
        phoneNumber=phone,
        otp=otp_code
    )
    
    print(f"OTP generated for {phone}: {otp_code}")
    
    # TODO: Later integrate SMS service here
    # For now, OTP is only stored in database (visible in admin panel)
    
    return JsonResponse({
        "status": "success",
        "message": "OTP generated successfully. Check admin panel for OTP.",
        # Include OTP in development (remove in production)
        "otp": otp_code if settings.DEBUG else None
    })

@api_view(['GET'])
def verify_otp(request):
    """Verify OTP from database and check if user exists"""
    phone = request.GET.get("phone")
    otp = request.GET.get("otp")
    
    if not phone or not otp:
        return JsonResponse({"status": "error", "message": "Phone and OTP required"}, status=400)
    
    try:
        # Get the most recent OTP for this phone
        otp_entry = OTP.objects.filter(phoneNumber=phone).first()
        
        if not otp_entry:
            return JsonResponse({"status": "error", "message": "No OTP found. Please request a new one."}, status=404)
        
        # Check if OTP is valid
        if not otp_entry.is_valid():
            return JsonResponse({"status": "error", "message": "OTP expired. Please request a new one."}, status=400)
        
        # Check if OTP matches
        if otp_entry.otp != otp:
            return JsonResponse({"status": "error", "message": "Invalid OTP"}, status=400)
        
        # Mark OTP as verified
        otp_entry.is_verified = True
        otp_entry.save()
        
        # Check if user exists
        try:
            user = User.objects.get(phoneNumber=phone)
            is_new_user = False
            user_data = {
                'upiName': user.upiName,
                'upiId': user.upiMail,
            }
        except User.DoesNotExist:
            is_new_user = True
            user_data = {}
        
        return JsonResponse({
            "status": "success",
            "message": "OTP verified successfully",
            "isNewUser": is_new_user,
            "phoneNumber": phone,
            **user_data
        })
        
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=500)

def login(upiName, phoneNumber):

    return JsonResponse({
        'upiName': upiName,
        'phoneNumber': phoneNumber,
        'status': 'success'
    })

def normalize_phone_number(phone):
    """Normalize phone number to ensure consistency.
    Returns both the original and +91 prefixed version if not already prefixed."""
    if not phone:
        return phone, phone
    
    phone = str(phone).strip()
    # If it starts with +91, also return version without +91
    if phone.startswith('+91'):
        without_prefix = phone[3:].lstrip('0')
        return phone, without_prefix
    # If it doesn't start with +91, also return version with +91
    else:
        phone_clean = phone.lstrip('0')
        with_prefix = '+91' + phone_clean
        return phone, with_prefix

@api_view(['POST'])
def SignUp(request):
    """Create new user account after OTP verification (only name required now)"""
    upiName = request.data.get('upiName')
    phoneNumber = request.data.get('phoneNumber')
    
    if not upiName or not phoneNumber:
        return JsonResponse({
            'error': 'Name and phone number are required',
            'status': 'error'
        }, status=400)
    
    # Verify OTP was completed for this phone number
    try:
        otp_entry = OTP.objects.filter(phoneNumber=phoneNumber, is_verified=True).first()
        if not otp_entry:
            return JsonResponse({
                'error': 'Please verify OTP first',
                'status': 'error'
            }, status=400)
    except Exception as e:
        return JsonResponse({
            'error': 'OTP verification required',
            'status': 'error'
        }, status=400)
    
    # Check if user already exists
    try:
        existing_user = User.objects.get(phoneNumber=phoneNumber)
        return JsonResponse({
            'error': 'User already exists',
            'status': 'error'
        }, status=400)
    except User.DoesNotExist:
        pass
    
    # Check if upiName is already taken
    try:
        User.objects.get(upiName=upiName)
        return JsonResponse({
            'error': 'UPI name already taken',
            'status': 'error'
        }, status=400)
    except User.DoesNotExist:
        pass
    
    try:
        upiId = generateUpiId(upiName)
    except Exception as e:
        return JsonResponse({
            'error': str(e),
            'status': 'error'
        }, status=500)
        
    try:
        # Create user
        user = User.objects.create(
            phoneNumber=phoneNumber,
            upiName=upiName,
            upiMail=upiId
        )
        user.save()
        
        # Create account with initial balance
        user_account = UserAccount.objects.create(user=user)
        user_account.save()
        
        return JsonResponse({
            'upiName': upiName,
            'phoneNumber': phoneNumber,
            'upiId': upiId,
            'status': 'success'
        })
        
    except Exception as e:
        return JsonResponse({
            'error': str(e),
            'status': 'error'
        }, status=500)


def generateUpiId(upiName):
    upi_id = upiName.lower().replace(" ", "") + "@upi"
    return upi_id


def searchNumber(request):
    phoneNumber = request.GET.get('phoneNumber')
    try:
        user = User.objects.get(phoneNumber=phoneNumber)
        return JsonResponse({
            'upiName': user.upiName,
            'upiId': user.upiMail,
            'status': 'success'
        })
    except User.DoesNotExist:
        return JsonResponse({
            'error': 'User not found',
            'status': 'error'
        }, status=404)
        
def searchByUpiId(request):
    upiId = request.GET.get('upiId')
    try:
        user = User.objects.get(upiMail=upiId)
        return JsonResponse({
            'upiName': user.upiName,
            'phoneNumber': user.phoneNumber,
            'status': 'success'
        })
    except User.DoesNotExist:
        return JsonResponse({
            'error': 'User not found',
            'status': 'error'
        }, status=404)
        
def getProfile(request):
    phoneNumber = request.GET.get('phoneNumber')
    try:
        user = User.objects.get(phoneNumber=phoneNumber)
        return JsonResponse({
            'upiName': user.upiName,
            'upiId': user.upiMail,
            'status': 'success'
        })
    except User.DoesNotExist:
        return JsonResponse({
            'error': 'User not found',
            'status': 'error'
        }, status=404)


def getBalance(request):
    phoneNumber = request.GET.get('phoneNumber')
    try:
        user = User.objects.get(phoneNumber=phoneNumber)
        user_account = UserAccount.objects.get(user=user)
        return JsonResponse({
            'balance': str(user_account.balance),
            'status': 'success'
        })
    except User.DoesNotExist:
        return JsonResponse({
            'error': 'User not found',
            'status': 'error'
        }, status=404)
    except UserAccount.DoesNotExist:
        return JsonResponse({
            'error': 'User account not found',
            'status': 'error'
        }, status=404)

@csrf_exempt
@api_view(['POST'])
def sendMoneyId(request):
    sender_phone = request.data.get('senderPhone')
    receiver_upi = request.data.get('receiverUpi')
    amount = Decimal(str(request.data.get('amount')))
    
    try:
        sender = User.objects.get(phoneNumber=sender_phone)
        sender_account = UserAccount.objects.get(user=sender)
    except User.DoesNotExist:
        return JsonResponse({
            'error': 'Sender not found',
            'status': 'error'
        }, status=404)
    except UserAccount.DoesNotExist:
        return JsonResponse({
            'error': 'Sender account not found',
            'status': 'error'
        }, status=404)
    
    try:
        receiver = User.objects.get(upiMail=receiver_upi)
        receiver_account = UserAccount.objects.get(user=receiver)
    except User.DoesNotExist:
        return JsonResponse({
            'error': 'Receiver not found',
            'status': 'error'
        }, status=404)
    except UserAccount.DoesNotExist:
        return JsonResponse({
            'error': 'Receiver account not found',
            'status': 'error'
        }, status=404)
    
    if sender_account.balance < amount:
        return JsonResponse({
            'error': 'Insufficient balance',
            'status': 'error'
        }, status=400)
    sender_account.balance = sender_account.balance - amount
    receiver_account.balance = receiver_account.balance + amount
    sender_account.save()
    receiver_account.save()
    
    try:
        transaction = Transaction.objects.create(
            sender=sender_account,
            receiver=receiver_account,
            amount=amount,
            status='completed'
        )
        transaction.save()
    except Exception as e:
        return JsonResponse({
            'error': str(e),
            'status': 'error'
        }, status=500)
    
    return JsonResponse({
        'message': f'Successfully sent {amount} to {receiver.upiName}',
        'status': 'success'
    })

@api_view(['POST'])
def sendMoneyPhone(request):
    sender_phone = request.data.get('senderPhone')
    receiver_phone = request.data.get('receiverPhone')
    amount = Decimal(str(request.data.get('amount')))
    
    try:
        sender = User.objects.get(phoneNumber=sender_phone)
        sender_account = UserAccount.objects.get(user=sender)
    except User.DoesNotExist:
        return JsonResponse({
            'error': 'Sender not found',
            'status': 'error'
        }, status=404)
    except UserAccount.DoesNotExist:
        return JsonResponse({
            'error': 'Sender account not found',
            'status': 'error'
        }, status=404)
    
    try:
        receiver = User.objects.get(phoneNumber=receiver_phone)
        receiver_account = UserAccount.objects.get(user=receiver)
    except User.DoesNotExist:
        return JsonResponse({
            'error': 'Receiver not found',
            'status': 'error'
        }, status=404)
    except UserAccount.DoesNotExist:
        return JsonResponse({
            'error': 'Receiver account not found',
            'status': 'error'
        }, status=404)
    
    if sender_account.balance < amount:
        return JsonResponse({
            'error': 'Insufficient balance',
            'status': 'error'
        }, status=400)
    sender_account.balance = sender_account.balance - amount
    receiver_account.balance = receiver_account.balance + amount
    sender_account.save()
    receiver_account.save()
    
    try:
        transaction = Transaction.objects.create(
            sender=sender_account,
            receiver=receiver_account,
            amount=amount,
            status='completed'
        )
        transaction.save()
    except Exception as e:
        return JsonResponse({
            'error': str(e),
            'status': 'error'
        }, status=500)
    
    return JsonResponse({
        'message': f'Successfully sent {amount} to {receiver.upiName}',
        'status': 'success'
    })

@api_view(['POST'])
def getTransactions(request):
    phoneNumber = request.data.get('phoneNumber')
    try:
        user = User.objects.get(phoneNumber=phoneNumber)
        user_account = UserAccount.objects.get(user=user)
        sent_transactions = Transaction.objects.filter(sender=user_account).values('receiver__user__upiName', 'amount', 'timestamp', 'status')
        received_transactions = Transaction.objects.filter(receiver=user_account).values('sender__user__upiName', 'amount', 'timestamp', 'status')
        
        transactions = {
            'sent': list(sent_transactions),
            'received': list(received_transactions)
        }
        
        return JsonResponse({
            'transactions': transactions,
            'status': 'success'
        })
    except User.DoesNotExist:
        return JsonResponse({
            'error': 'User not found',
            'status': 'error'
        }, status=404)
    except UserAccount.DoesNotExist:
        return JsonResponse({
            'error': 'User account not found',
            'status': 'error'
        }, status=404)

@api_view(['GET'])        
def checkHasAccount(request):
    phoneNumber = request.GET.get('phoneNumber')
    print('here')
    try:
        user = User.objects.get(phoneNumber=phoneNumber)
        user_account = UserAccount.objects.get(user=user)
        return JsonResponse({
            'hasAccount': True,
            'status': 'success'
        })
    except User.DoesNotExist:
        return JsonResponse({
            'hasAccount': False,
            'status': 'error'
        }, status=404)
    except UserAccount.DoesNotExist:
        return JsonResponse({
            'hasAccount': False,
            'status': 'error'
        }, status=404)

# Money Request APIs
@api_view(['POST'])
def createMoneyRequest(request):
    requester_phone = request.data.get('requesterPhone')
    requestee_phone = request.data.get('requesteePhone')
    amount = Decimal(str(request.data.get('amount')))
    message = request.data.get('message', '')
    
    try:
        requester = User.objects.get(phoneNumber=requester_phone)
        requester_account = UserAccount.objects.get(user=requester)
    except User.DoesNotExist:
        return JsonResponse({
            'error': 'Requester not found',
            'status': 'error'
        }, status=404)
    except UserAccount.DoesNotExist:
        return JsonResponse({
            'error': 'Requester account not found',
            'status': 'error'
        }, status=404)
    
    try:
        requestee = User.objects.get(phoneNumber=requestee_phone)
        requestee_account = UserAccount.objects.get(user=requestee)
    except User.DoesNotExist:
        return JsonResponse({
            'error': 'Requestee not found',
            'status': 'error'
        }, status=404)
    except UserAccount.DoesNotExist:
        return JsonResponse({
            'error': 'Requestee account not found',
            'status': 'error'
        }, status=404)
    
    try:
        money_request = MoneyRequest.objects.create(
            requester=requester_account,
            requestee=requestee_account,
            amount=amount,
            message=message,
            status='pending'
        )
        money_request.save()
        
        return JsonResponse({
            'message': f'Money request of ₹{amount} sent to {requestee.upiName}',
            'requestId': money_request.id,
            'status': 'success'
        })
    except Exception as e:
        return JsonResponse({
            'error': str(e),
            'status': 'error'
        }, status=500)

@api_view(['POST'])
def createMoneyRequestByUpi(request):
    requester_phone = request.data.get('requesterPhone')
    requestee_upi = request.data.get('requesteeUpi')
    amount = Decimal(str(request.data.get('amount')))
    message = request.data.get('message', '')
    
    try:
        requester = User.objects.get(phoneNumber=requester_phone)
        requester_account = UserAccount.objects.get(user=requester)
    except User.DoesNotExist:
        return JsonResponse({
            'error': 'Requester not found',
            'status': 'error'
        }, status=404)
    except UserAccount.DoesNotExist:
        return JsonResponse({
            'error': 'Requester account not found',
            'status': 'error'
        }, status=404)
    
    try:
        requestee = User.objects.get(upiMail=requestee_upi)
        requestee_account = UserAccount.objects.get(user=requestee)
    except User.DoesNotExist:
        return JsonResponse({
            'error': 'Requestee not found',
            'status': 'error'
        }, status=404)
    except UserAccount.DoesNotExist:
        return JsonResponse({
            'error': 'Requestee account not found',
            'status': 'error'
        }, status=404)
    
    try:
        money_request = MoneyRequest.objects.create(
            requester=requester_account,
            requestee=requestee_account,
            amount=amount,
            message=message,
            status='pending'
        )
        money_request.save()
        
        return JsonResponse({
            'message': f'Money request of ₹{amount} sent to {requestee.upiName}',
            'requestId': money_request.id,
            'status': 'success'
        })
    except Exception as e:
        return JsonResponse({
            'error': str(e),
            'status': 'error'
        }, status=500)

@api_view(['GET'])
def getMoneyRequests(request):
    phone_number = request.GET.get('phoneNumber')
    
    try:
        user = User.objects.get(phoneNumber=phone_number)
        user_account = UserAccount.objects.get(user=user)
        
        # Get sent requests
        sent_requests = MoneyRequest.objects.filter(requester=user_account).values(
            'id', 'requestee__user__upiName', 'requestee__user__phoneNumber', 
            'amount', 'message', 'status', 'created_at', 'updated_at'
        )
        
        # Get received requests
        received_requests = MoneyRequest.objects.filter(requestee=user_account).values(
            'id', 'requester__user__upiName', 'requester__user__phoneNumber',
            'amount', 'message', 'status', 'created_at', 'updated_at'
        )
        
        return JsonResponse({
            'sentRequests': list(sent_requests),
            'receivedRequests': list(received_requests),
            'status': 'success'
        })
        
    except User.DoesNotExist:
        return JsonResponse({
            'error': 'User not found',
            'status': 'error'
        }, status=404)
    except UserAccount.DoesNotExist:
        return JsonResponse({
            'error': 'User account not found',
            'status': 'error'
        }, status=404)

@api_view(['POST'])
def updateRequestStatus(request):
    request_id = request.data.get('requestId')
    new_status = request.data.get('status')  # 'approved', 'rejected', 'cancelled'
    phone_number = request.data.get('phoneNumber')
    
    try:
        money_request = MoneyRequest.objects.get(id=request_id)
        user = User.objects.get(phoneNumber=phone_number)
        user_account = UserAccount.objects.get(user=user)
        
        # Check if user has permission to update this request
        if money_request.requester != user_account and money_request.requestee != user_account:
            return JsonResponse({
                'error': 'Unauthorized to update this request',
                'status': 'error'
            }, status=403)
        
        # Validate status transitions
        if new_status == 'cancelled' and money_request.requester != user_account:
            return JsonResponse({
                'error': 'Only requester can cancel the request',
                'status': 'error'
            }, status=403)
        
        if new_status in ['approved', 'rejected'] and money_request.requestee != user_account:
            return JsonResponse({
                'error': 'Only requestee can approve or reject the request',
                'status': 'error'
            }, status=403)
        
        if money_request.status != 'pending':
            return JsonResponse({
                'error': 'Request has already been processed',
                'status': 'error'
            }, status=400)
        
        # If approved, process the payment
        if new_status == 'approved':
            requestee_account = money_request.requestee
            requester_account = money_request.requester
            amount = money_request.amount
            
            # Check if requestee has sufficient balance
            if requestee_account.balance < amount:
                return JsonResponse({
                    'error': 'Insufficient balance to approve request',
                    'status': 'error'
                }, status=400)
            
            # Process the payment
            requestee_account.balance -= amount
            requester_account.balance += amount
            requestee_account.save()
            requester_account.save()
            
            # Create transaction record
            transaction = Transaction.objects.create(
                sender=requestee_account,
                receiver=requester_account,
                amount=amount,
                status='completed'
            )
            transaction.save()
        
        # Update request status
        money_request.status = new_status
        money_request.save()
        
        return JsonResponse({
            'message': f'Request {new_status} successfully',
            'status': 'success'
        })
        
    except MoneyRequest.DoesNotExist:
        return JsonResponse({
            'error': 'Request not found',
            'status': 'error'
        }, status=404)
    except User.DoesNotExist:
        return JsonResponse({
            'error': 'User not found',
            'status': 'error'
        }, status=404)
    except UserAccount.DoesNotExist:
        return JsonResponse({
            'error': 'User account not found',
            'status': 'error'
        }, status=404)
    except Exception as e:
        return JsonResponse({
            'error': str(e),
            'status': 'error'
        }, status=500)