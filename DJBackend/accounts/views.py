from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from twilio.rest import Client
from django.conf import settings
import random
from rest_framework.decorators import api_view
from .models import User
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

@api_view(['POST'])
def SignUp(request):
    upiName = request.data.get('upiName')
    phoneNumber = request.data.get('phoneNumber')
    
    try:
        upiNameTaken= User.objects.get(upiName=upiName)
        return JsonResponse({
            'error': 'UPI Name already exists',
            'status': 'error'
        }, status=400)
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