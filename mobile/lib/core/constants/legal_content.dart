class LegalSection {
  final String title;
  final String body;
  final List<String>? bulletPoints;

  const LegalSection({
    required this.title,
    required this.body,
    this.bulletPoints,
  });
}

class LegalContent {
  static const String brandName = "Retailza";
  static const String companyName = "TechMasters Innovations Private Limited";
  static const String privacyEmail = "privacy@retailza.com";
  static const String supportEmail = "support@retailza.com";
  static const String lastUpdated = "September 20, 2026";
  static const String copyrightNotice =
      "© 2026 TechMasters Innovations Private Limited. All rights reserved.";
  static const String copyrightSubtitle =
      "Retailza™ is a proprietary product of TechMasters Innovations Private Limited. Unauthorized duplication, reverse engineering, or redistribution is strictly prohibited.";

  // ==================== PRIVACY POLICY ====================
  static const String privacyPolicyTitle = "Privacy Policy";
  static const String privacyPolicyIntro =
      "Retailza is a product of TechMasters Innovations Private Limited. We respect your privacy and are committed to protecting the information you provide while using the Retailza mobile application and related SaaS services.";

  static const List<LegalSection> privacyPolicySections = [
    LegalSection(
      title: "1. Information We Collect",
      body: "Retailza may collect information required to provide the service, including:",
      bulletPoints: [
        "Mobile number used for login and OTP verification",
        "Store owner name and contact details",
        "Shop name, category, and physical address",
        "Product catalog and inventory information (names, prices, barcode, units, stock)",
        "Sales, billing, and transaction records",
        "Customer and credit/Khata information entered by the shopkeeper",
        "Retailza SaaS subscription and payment verification records",
        "Basic technical information required for security, performance, and service operation",
      ],
    ),
    LegalSection(
      title: "2. How We Use Your Information",
      body: "Your information is strictly used to:",
      bulletPoints: [
        "Create, authenticate, and manage your Retailza merchant account",
        "Provide shop-management, inventory tracking, and POS billing features",
        "Record sales and compute financial summaries",
        "Manage customer credit/Khata ledgers and repayment records",
        "Display your shop dashboard, metrics, and past sales invoices",
        "Process and verify Retailza Pro subscriptions",
        "Provide customer support and technical assistance",
        "Maintain security, prevent unauthorized access, and troubleshoot problems",
      ],
    ),
    LegalSection(
      title: "3. Customer Information (Khata Ledger)",
      body:
          "Retailza allows shopkeepers to enter customer information such as customer name, mobile number, address, and credit transactions.\n\nThis information is entered by the shopkeeper for their own retail business purposes. Shopkeepers are solely responsible for ensuring that they have the appropriate permission, consent, or lawful basis from their customers to maintain such records.",
    ),
    LegalSection(
      title: "4. Payment Information",
      body:
          "Retailza subscription payments (for Retailza Pro) are completely separate from customer payments made to the shopkeeper for store items.\n\nRetailza uses authorized, RBI-compliant third-party payment gateways (such as Razorpay) to process subscription payments.\n\nRetailza does NOT require, collect, or store sensitive payment credentials such as UPI PIN, Debit/Credit Card PIN, or CVV.",
    ),
    LegalSection(
      title: "5. Data Security",
      body:
          "We implement industry-standard technical and organizational safeguards to protect your information, including encrypted HTTPS communication, JWT session authentication, database encryption, and strict access controls.\n\nHowever, please note that no internet-connected system or electronic storage can guarantee 100% absolute security.",
    ),
    LegalSection(
      title: "6. Data Sharing & Third-Party Service Providers",
      body:
          "We may use trusted third-party service providers required to operate Retailza—such as telecom SMS/OTP gateways (e.g., Fast2SMS), payment gateways (Razorpay), cloud hosting, and database infrastructure.\n\nWe DO NOT sell, rent, or trade your shop's business records or your customer records to any third party for advertising or marketing purposes.",
    ),
    LegalSection(
      title: "7. Data Retention",
      body:
          "We retain your store data for as long as your Retailza account remains active to provide continuous service, maintain statutory billing records, resolve disputes, and comply with applicable legal and financial obligations under Indian law.",
    ),
    LegalSection(
      title: "8. Account Deletion",
      body:
          "You can request deletion of your Retailza account and associated business records by contacting our support team at $supportEmail or submitting an in-app request.\n\nUpon verification, your personal information and store records will be permanently deleted, except where retention is strictly required for legal, tax, or regulatory compliance.",
    ),
    LegalSection(
      title: "9. Account Security Best Practices",
      body:
          "Never share your OTP, UPI PIN, Debit/Credit Card PIN, CVV, or passwords with anyone.\n\nRetailza and TechMasters Innovations Private Limited personnel will NEVER ask you for your confidential PIN or password.",
    ),
    LegalSection(
      title: "10. Changes to This Policy",
      body:
          "We may update this Privacy Policy periodically to reflect service updates or regulatory requirements. Material changes will be communicated via the Retailza application with the updated effective date.",
    ),
  ];

  // ==================== TERMS & CONDITIONS ====================
  static const String termsConditionsTitle = "Terms & Conditions";
  static const String termsConditionsIntro =
      "Welcome to Retailza, a cloud-based retail point-of-sale and store management service operated by TechMasters Innovations Private Limited. By downloading, registering, or using Retailza, you agree to be bound by these Terms & Conditions.";

  static const List<LegalSection> termsConditionsSections = [
    LegalSection(
      title: "1. Acceptance & Eligibility",
      body:
          "By accessing or using the Retailza mobile application or backend services, you confirm that you are at least 18 years of age, legally capable of entering into binding contracts, and authorized to represent your business or shop.",
    ),
    LegalSection(
      title: "2. Description of Services",
      body: "Retailza provides digital retail management software designed for Indian Kirana and retail merchants, including:",
      bulletPoints: [
        "10-second fast POS billing and invoice generation",
        "Product catalog and live inventory stock tracking",
        "Customer Khata (digital credit ledger) and repayment recording",
        "Dynamic NPCI UPI QR code generation for counter payments",
        "Daily, weekly, and monthly store performance analytics",
      ],
    ),
    LegalSection(
      title: "3. Merchant Accounts & Responsibilities",
      body:
          "You are responsible for maintaining the accuracy of your store details, GSTIN (if applicable), and contact numbers. You agree to safeguard your login credentials and OTPs. All activities conducted under your store account remain your sole responsibility.",
    ),
    LegalSection(
      title: "4. Customer Data & Merchant Ownership",
      body:
          "You retain ownership of all product lists, pricing, sales data, and customer records entered into Retailza. TechMasters Innovations Private Limited acts as a service provider and data processor.\n\nYou represent that you have lawful authority to record customer names and phone numbers for your store's Khata credit management.",
    ),
    LegalSection(
      title: "5. SaaS Subscriptions & Payments",
      body:
          "Retailza operates on a low-cost subscription model (e.g., ₹49/month or designated promotional plans). Subscriptions are billed in advance via authorized payment processors.\n\nSubscription fees are non-refundable once the billing period has commenced. In the event of subscription lapse, access to premium features may be restricted until renewal.",
    ),
    LegalSection(
      title: "6. Counter UPI Payments & Disclaimer",
      body:
          "Retailza allows you to generate dynamic UPI QR codes populated with your own UPI VPA. Customer payments made via UPI transfer directly into your designated bank account.\n\nTechMasters Innovations Private Limited is NOT a bank or payment intermediary and holds no custody of your retail customer funds. Any disputes regarding counter payments remain strictly between you and your customer or acquiring bank.",
    ),
    LegalSection(
      title: "7. Prohibited Uses",
      body: "You agree not to use Retailza for:",
      bulletPoints: [
        "Sale or billing of prohibited, illicit, or counterfeit goods under Indian law",
        "Attempting to decompile, reverse-engineer, or disassemble the Retailza application",
        "Using automated bots, scrapers, or unauthorized API access",
        "Impersonating another merchant or business entity",
      ],
    ),
    LegalSection(
      title: "8. Intellectual Property & Copyright",
      body:
          "All intellectual property rights, trademarks, brand names, visual interfaces, algorithms, and source code associated with Retailza are the exclusive property of TechMasters Innovations Private Limited. No license or title is transferred to you other than a limited, non-exclusive right to use the software.",
    ),
    LegalSection(
      title: "9. Limitation of Liability",
      body:
          "Retailza is provided on an 'AS-IS' and 'AS-AVAILABLE' basis. To the maximum extent permitted by applicable law, TechMasters Innovations Private Limited shall not be liable for any indirect, incidental, or consequential damages, lost profits, or data loss resulting from network interruptions or device malfunctions.",
    ),
    LegalSection(
      title: "10. Governing Law & Dispute Resolution",
      body:
          "These Terms are governed by and construed in accordance with the laws of India. Any disputes arising out of or related to these Terms shall be subject to the exclusive jurisdiction of the competent courts in India.",
    ),
  ];

  // ==================== COPYRIGHT NOTICE ====================
  static const String copyrightTitle = "Copyright & Legal Notice";
  static const String copyrightFullStatement =
      "Retailza™ is a registered product developed, owned, and operated by TechMasters Innovations Private Limited.\n\n"
      "Copyright © 2026 TechMasters Innovations Private Limited. All rights reserved.\n\n"
      "All trademarks, logos, brand assets, user interface layouts, software code, and documentation related to Retailza are protected under Indian and international copyright and intellectual property laws.\n\n"
      "No portion of this software, its design, or its underlying architecture may be copied, reproduced, republished, modified, distributed, or reverse engineered in any form without prior express written permission from TechMasters Innovations Private Limited.";
}
