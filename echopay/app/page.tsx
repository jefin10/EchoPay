'use client';

import Image from "next/image";
import { useState } from "react";

export default function Home() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const apkDownloadUrl = "https://github.com/jefin10/EchoPay/releases/latest/download/app-release.apk";

  return (
    <div className="min-h-screen bg-white">
      {/* Navigation */}
      <nav className="fixed top-0 w-full bg-white/95 backdrop-blur-sm z-50 border-b border-gray-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center gap-2">
              <Image
                src="/symbol-logo.png"
                alt="EchoPay Logo"
                width={32}
                height={32}
                className="w-8 h-8"
              />
              <span className="text-xl font-semibold text-gray-900">EchoPay</span>
            </div>
            
            {/* Desktop Navigation */}
            <div className="hidden md:flex items-center gap-8">
              <a href="#features" className="text-gray-600 hover:text-[#0066FF] transition-colors">Features</a>
              <a href={apkDownloadUrl} target="_blank" rel="noopener noreferrer" className="bg-[#0066FF] text-white px-6 py-2.5 rounded-full hover:bg-[#0052CC] transition-colors font-medium">
                Download App
              </a>
            </div>

            {/* Mobile menu button */}
            <button 
              className="md:hidden p-2"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
              </svg>
            </button>
          </div>
        </div>

        {/* Mobile menu */}
        {mobileMenuOpen && (
          <div className="md:hidden border-t border-gray-100 bg-white">
            <div className="px-4 py-4 space-y-3">
              <a href="#features" className="block text-gray-600 hover:text-[#0066FF] py-2">Features</a>
              <a href={apkDownloadUrl} target="_blank" rel="noopener noreferrer" className="block bg-[#0066FF] text-white px-6 py-2.5 rounded-full text-center hover:bg-[#0052CC] transition-colors font-medium">
                Download App
              </a>
            </div>
          </div>
        )}
      </nav>

      {/* Hero Section */}
      <section className="pt-32 pb-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div>
              <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-gray-900 leading-tight mb-6">
                Voice-Powered UPI Payments
              </h1>
              <p className="text-lg sm:text-xl text-gray-600 mb-8 leading-relaxed">
                Send money instantly with just your voice. EchoPay makes UPI payments faster, easier, and more accessible than ever before.
              </p>
              <div className="flex flex-col sm:flex-row gap-4">
                <a 
                  href={apkDownloadUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center justify-center bg-[#0066FF] text-white px-8 py-4 rounded-full hover:bg-[#0052CC] transition-colors font-semibold text-lg"
                >
                  Download App
                  <svg className="w-5 h-5 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                  </svg>
                </a>
              </div>
            </div>
            <div className="relative">
              <div className="relative w-full max-w-md mx-auto">
                <div className="absolute inset-0 bg-gradient-to-r from-[#0066FF] to-[#338EFF] rounded-3xl blur-3xl opacity-20"></div>
                <Image
                  src="/full-logo.png"
                  alt="EchoPay App"
                  width={400}
                  height={400}
                  className="relative z-10 w-full h-auto"
                />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-20 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-4">
              Everything You Need for Seamless Payments
            </h2>
            <p className="text-lg text-gray-600 max-w-2xl mx-auto">
              EchoPay combines cutting-edge voice technology with secure UPI payments
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            {/* Voice Payments */}
            <div className="bg-white p-8 rounded-2xl shadow-sm hover:shadow-md transition-shadow">
              <div className="w-14 h-14 bg-[#0066FF]/10 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-[#0066FF]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">Voice Commands</h3>
              <p className="text-gray-600 leading-relaxed">
                Simply say "Send ₹500 to John" and let our AI handle the rest. Natural language processing makes payments effortless.
              </p>
            </div>

            {/* QR Code */}
            <div className="bg-white p-8 rounded-2xl shadow-sm hover:shadow-md transition-shadow">
              <div className="w-14 h-14 bg-[#00C853]/10 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-[#00C853]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">Scan & Pay</h3>
              <p className="text-gray-600 leading-relaxed">
                Scan any UPI QR code instantly or generate your own QR code for receiving payments quickly and securely.
              </p>
            </div>

            {/* Contact Payments */}
            <div className="bg-white p-8 rounded-2xl shadow-sm hover:shadow-md transition-shadow">
              <div className="w-14 h-14 bg-[#2196F3]/10 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-[#2196F3]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">Pay to Contacts</h3>
              <p className="text-gray-600 leading-relaxed">
                Send money directly to your phone contacts. No need to remember UPI IDs or account numbers.
              </p>
            </div>

            {/* Phone Number */}
            <div className="bg-white p-8 rounded-2xl shadow-sm hover:shadow-md transition-shadow">
              <div className="w-14 h-14 bg-[#FF9800]/10 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-[#FF9800]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">Pay by Phone Number</h3>
              <p className="text-gray-600 leading-relaxed">
                Transfer money using just a phone number. Fast, simple, and works with any UPI-enabled number.
              </p>
            </div>

            {/* UPI ID */}
            <div className="bg-white p-8 rounded-2xl shadow-sm hover:shadow-md transition-shadow">
              <div className="w-14 h-14 bg-[#E91E63]/10 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-[#E91E63]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 12a4 4 0 10-8 0 4 4 0 008 0zm0 0v1.5a2.5 2.5 0 005 0V12a9 9 0 10-9 9m4.5-1.206a8.959 8.959 0 01-4.5 1.207" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">Pay to UPI ID</h3>
              <p className="text-gray-600 leading-relaxed">
                Send payments to any UPI ID directly. Compatible with all major UPI apps and payment platforms.
              </p>
            </div>

            {/* Security */}
            <div className="bg-white p-8 rounded-2xl shadow-sm hover:shadow-md transition-shadow">
              <div className="w-14 h-14 bg-[#00BCD4]/10 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-[#00BCD4]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">Biometric Security</h3>
              <p className="text-gray-600 leading-relaxed">
                Your payments are protected with fingerprint and face recognition. Bank-grade security for every transaction.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Voice Commands Showcase */}
      <section className="py-20 bg-gradient-to-br from-[#0066FF] to-[#0052CC]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
              Just Say It, We'll Do It
            </h2>
            <p className="text-lg text-white/90 max-w-2xl mx-auto">
              Our AI understands natural language. Talk to EchoPay like you talk to a friend.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-5xl mx-auto">
            <div className="bg-white/10 backdrop-blur-sm p-6 rounded-xl border border-white/20">
              <p className="text-white text-lg">"Send ₹500 to John"</p>
            </div>
            <div className="bg-white/10 backdrop-blur-sm p-6 rounded-xl border border-white/20">
              <p className="text-white text-lg">"Check my balance"</p>
            </div>
            <div className="bg-white/10 backdrop-blur-sm p-6 rounded-xl border border-white/20">
              <p className="text-white text-lg">"Request ₹300 from Mom"</p>
            </div>
            <div className="bg-white/10 backdrop-blur-sm p-6 rounded-xl border border-white/20">
              <p className="text-white text-lg">"Pay 9876543210"</p>
            </div>
            <div className="bg-white/10 backdrop-blur-sm p-6 rounded-xl border border-white/20">
              <p className="text-white text-lg">"Show transaction history"</p>
            </div>
            <div className="bg-white/10 backdrop-blur-sm p-6 rounded-xl border border-white/20">
              <p className="text-white text-lg">"Generate my QR code"</p>
            </div>
          </div>
        </div>
      </section>

      {/* Download Section */}
      <section id="download" className="py-20">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-4">
            Ready to Experience the Future of Payments?
          </h2>
          <p className="text-lg text-gray-600 mb-10">
            Download EchoPay now and start making voice-powered UPI payments
          </p>
          
          <a 
            href={apkDownloadUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center justify-center bg-[#0066FF] text-white px-10 py-5 rounded-full hover:bg-[#0052CC] transition-colors font-semibold text-xl shadow-lg"
          >
            Download App
            <svg className="w-6 h-6 ml-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
            </svg>
          </a>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col md:flex-row justify-between items-center gap-6">
            <div className="flex items-center gap-2">
              <Image
                src="/symbol-logo.png"
                alt="EchoPay"
                width={32}
                height={32}
                className="w-8 h-8"
              />
              <span className="text-xl font-semibold">EchoPay</span>
            </div>
            
            <p className="text-gray-400 text-sm text-center">
              Voice-powered UPI payments for everyone
            </p>
            
            <div className="flex items-center gap-6 text-sm text-gray-400">
              <a href="#features" className="hover:text-white transition-colors">Features</a>
              <a href={apkDownloadUrl} target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors">Download</a>
            </div>
          </div>
          
          <div className="border-t border-gray-800 mt-8 pt-8 text-center text-sm text-gray-400">
            <p>&copy; 2026 EchoPay. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
