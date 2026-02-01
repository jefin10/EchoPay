from django.contrib import admin
from .models import User, UserAccount, Transaction, MoneyRequest, OTP

# Register your models here.
@admin.register(OTP)
class OTPAdmin(admin.ModelAdmin):
    list_display = ['phoneNumber', 'otp', 'created_at', 'is_verified']
    list_filter = ['is_verified', 'created_at']
    search_fields = ['phoneNumber', 'otp']
    readonly_fields = ['created_at']
    ordering = ['-created_at']

@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ['phoneNumber', 'upiName', 'upiMail']
    search_fields = ['phoneNumber', 'upiName', 'upiMail']

@admin.register(UserAccount)
class UserAccountAdmin(admin.ModelAdmin):
    list_display = ['user', 'balance', 'created_at', 'updated_at']
    list_filter = ['created_at']

@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ['sender', 'receiver', 'amount', 'status', 'timestamp']
    list_filter = ['status', 'timestamp']

@admin.register(MoneyRequest)
class MoneyRequestAdmin(admin.ModelAdmin):
    list_display = ['requester', 'requestee', 'amount', 'status', 'created_at']
    list_filter = ['status', 'created_at']
