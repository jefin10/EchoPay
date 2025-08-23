from django.db import models

# Create your models here.
class User(models.Model):
    phoneNumber= models.CharField(max_length=15, unique=True)
    upiName = models.CharField(max_length=100)
    upiMail=models.EmailField(max_length=254, unique=True)

class UserAccount(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    balance = models.DecimalField(max_digits=10, decimal_places=2, default=5000.00)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.user.upiName} - Balance: {self.balance}"

class Transaction(models.Model):
    sender = models.ForeignKey(UserAccount, related_name='sent_transactions', on_delete=models.CASCADE)
    receiver = models.ForeignKey(UserAccount, related_name='received_transactions', on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    timestamp = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, choices=[('pending', 'Pending'), ('completed', 'Completed'), ('failed', 'Failed')], default='pending')
    
    def __str__(self):
        return f"Transaction from {self.sender.user.upiName} to {self.receiver.user.upiName} - Amount: {self.amount} - Status: {self.status}"