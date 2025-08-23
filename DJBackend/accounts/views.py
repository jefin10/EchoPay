from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from twilio.rest import Client
from django.conf import settings
import random
from decimal import Decimal
from rest_framework.decorators import api_view
from .models import User
from .models import UserAccount,Transaction
# Create your views here.

otp_store = {}

@api_view(['GET'])
def send_otp(request):
    phone = request.GET.get("phone")
    otp = str(random.randint(100000, 999999))
    # Always store phone in +91 format
    store_phone = phone
    if not store_phone.startswith('+91'):
        store_phone = '+91' + store_phone.lstrip('0')
    otp_store[phone] = otp  
    print(store_phone)
    client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
    message = client.messages.create(
        body=f"Your OTP is {otp}",
        from_=settings.TWILIO_PHONE_NUMBER,
        to=store_phone
    )
    return JsonResponse({"status": "OTP sent"})

def verify_otp(request):
    phone = request.GET.get("phone")
    otp = request.GET.get("otp")
    if otp_store.get(phone) == otp:
        return JsonResponse({"status": "Verified"})
    return JsonResponse({"status": "Failed"})

def login(upiName, phoneNumber):

    return JsonResponse({
        'upiName': upiName,
        'phoneNumber': phoneNumber,
        'status': 'success'
    })

@api_view(['POST'])
def SignUp(request):
    upiName = request.data.get('upiName')
    phoneNumber = request.data.get('phoneNumber')
    
    try:
        upiNameTaken= User.objects.get(upiName=upiName)
        if(upiNameTaken.phoneNumber==phoneNumber):
            return login(upiName,phoneNumber)
    except User.DoesNotExist:
        pass
    try:
        upiId= generateUpiId(upiName)
    except Exception as e:
        return JsonResponse({
            'error': str(e),
            'status': 'error'
        }, status=500)
        
    try:
        user = User.objects.create(
            phoneNumber=phoneNumber,
            upiName=upiName,
            upiMail=upiId
        )
        user.save()
    except Exception as e:
        return JsonResponse({
            'error': str(e),
            'status': 'error'
        }, status=500)
    
    try:
        user_account = UserAccount.objects.create(user=user)
        user_account.save()
    except Exception as e:
        return JsonResponse({
            'error': str(e),
            'status': 'error'
        }, status=500)
    
    
    return JsonResponse({
        'upiName': upiName,
        'phoneNumber': phoneNumber,
        'upiId': upiId,
        'status': 'success'
    })


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