import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "EchoPay",
  description:
    "EchoPay is a voice-powered UPI payments platform for fast, secure, and accessible money transfers.",
  applicationName: "EchoPay",
  icons: {
    icon: [{ url: "/symbol-logo.png", type: "image/png" }],
    shortcut: [{ url: "/symbol-logo.png", type: "image/png" }],
    apple: [{ url: "/symbol-logo.png", type: "image/png" }],
  },
  openGraph: {
    title: "EchoPay",
    description:
      "Voice-powered UPI payments for fast, secure, and accessible money transfers.",
    siteName: "EchoPay",
    type: "website",
    images: [
      {
        url: "/symbol-logo.png",
        width: 512,
        height: 512,
        alt: "EchoPay symbol logo",
      },
    ],
  },
  twitter: {
    card: "summary",
    title: "EchoPay",
    description:
      "Voice-powered UPI payments for fast, secure, and accessible money transfers.",
    images: ["/symbol-logo.png"],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
