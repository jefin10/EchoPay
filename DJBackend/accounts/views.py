from django.shortcuts import render

# Create your views here.
def SignUp():
    email = request.data.get('email')
    fullName = request.data.get('fullName')
    phoneNumber = request.data.get('phoneNumber')
    
    