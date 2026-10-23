from .views import SignUp, send_otp, verify_otp,searchNumber,checkHasAccount,searchByUpiId,sendMoneyPhone,getProfile, getTransactions, getBalance, sendMoneyId, createMoneyRequest, createMoneyRequestByUpi, getMoneyRequests, updateRequestStatus
from django.urls import path

urlpatterns = [
    path('signup/', SignUp, name='signup'),
    path('send_otp/', send_otp, name='send_otp'),
    path('verify_otp/', verify_otp, name='verify_otp'),
    path('searchPhonenumber/', searchNumber, name='searchPhoneNumber'),
    path('searchByUpiId/', searchByUpiId, name='searchByUpiId'),
    path('getProfile/', getProfile, name='getProfile'),
    path('getBalance/', getBalance, name='getBalance'),
    path('sendMoneyId/',sendMoneyId,name='sendMoneyId'),
    path('getTransactions/',getTransactions,name='getTransactions'),
    path('sendMoneyPhone/',sendMoneyPhone,name='sendMoneyPhone'),
    path('checkHasAccount/', checkHasAccount, name='checkAccount'),
    path('createMoneyRequest/', createMoneyRequest, name='createMoneyRequest'),
    path('createMoneyRequestByUpi/', createMoneyRequestByUpi, name='createMoneyRequestByUpi'),
    path('getMoneyRequests/', getMoneyRequests, name='getMoneyRequests'),
    path('updateRequestStatus/', updateRequestStatus, name='updateRequestStatus'),
]
