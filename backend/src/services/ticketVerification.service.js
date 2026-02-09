const Tesseract = require('tesseract.js');
const sharp = require('sharp');
const path = require('path');
const fs = require('fs');
const Request = require('../models/Request');

const ticketVerificationService = {
  /**
   * Patterns for extracting ticket information
   */
  patterns: {
    // Booking ID patterns for various platforms
    bookingId: /(?:booking|order|confirmation|ref|txn|transaction|id|no)[\s#:.]*([A-Z0-9]{6,})/gi,
    // Total Amount pattern - matches "Total Amount" followed by amount anywhere on same line
    totalAmount: /total\s*amount[\s:₹Rs.INR]*([0-9,]+(?:\.[0-9]{1,2})?)/gi,
    // Pattern for "Total Amount" on left and "₹ X,XXX.XX" on right (separated by whitespace)
    totalAmountSplit: /total\s*amount.*?[₹₨]\s*([0-9,]+(?:\.[0-9]{1,2})?)/gi,
    // Amount patterns (Indian Rupee) - improved to handle various formats
    amount: /(?:₹|rs\.?|inr|total|amount|paid|price|cost|pay|grand\s*total|net\s*amount|final\s*amount)[\s:₹]*([0-9,]+(?:\.[0-9]{1,2})?)/gi,
    // Additional pattern for amounts with rupee symbol after keywords
    amountAlt: /([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:₹|rs\.?|inr|rupees?)/gi,
    // Standalone rupee pattern (₹ followed by number, with optional space)
    amountRupee: /[₹₨]\s*([0-9,]+(?:\.[0-9]{1,2})?)/gi,
    // Date patterns
    date: /(\d{1,2}[\/-]\d{1,2}[\/-]\d{2,4})/g,
    // Time patterns
    time: /(\d{1,2}:\d{2}\s*(?:am|pm)?)/gi,
  },

  /**
   * Platform-specific identifiers
   */
  platforms: {
    bookmyshow: ['bookmyshow', 'book my show', 'bms'],
    paytm: ['paytm', 'paytm insider'],
    zomato: ['zomato'],
    swiggy: ['swiggy'],
    ticketmaster: ['ticketmaster'],
    makemytrip: ['makemytrip', 'mmt'],
  },

  /**
   * Preprocess image for better OCR accuracy
   */
  async preprocessImage(imagePath) {
    const ext = path.extname(imagePath);
    const processedPath = imagePath.replace(ext, `_processed${ext}`);

    try {
      await sharp(imagePath)
        .resize(1500, null, { withoutEnlargement: false, fit: 'inside' })
        .greyscale()
        .normalize()
        .sharpen()
        .toFile(processedPath);

      return processedPath;
    } catch (error) {
      console.error('Image preprocessing failed:', error);
      return imagePath; // Return original if processing fails
    }
  },

  /**
   * Extract text from image using Tesseract OCR
   */
  async extractText(imagePath) {
    let processedPath = null;

    try {
      // Preprocess image for better accuracy
      processedPath = await this.preprocessImage(imagePath);

      console.log('Starting OCR extraction on:', processedPath);

      const { data } = await Tesseract.recognize(processedPath, 'eng', {
        logger: (m) => {
          if (m.status === 'recognizing text') {
            console.log(`OCR Progress: ${Math.round(m.progress * 100)}%`);
          }
        },
      });

      // Cleanup processed image
      if (processedPath !== imagePath && fs.existsSync(processedPath)) {
        fs.unlinkSync(processedPath);
      }

      return {
        text: data.text,
        confidence: data.confidence,
        words: data.words || [],
      };
    } catch (error) {
      console.error('OCR extraction failed:', error);
      
      // Cleanup on error
      if (processedPath && processedPath !== imagePath && fs.existsSync(processedPath)) {
        fs.unlinkSync(processedPath);
      }
      
      return { text: '', confidence: 0, words: [] };
    }
  },

  /**
   * Detect which platform the ticket is from
   */
  detectPlatform(text) {
    const lowerText = text.toLowerCase();

    for (const [platform, identifiers] of Object.entries(this.platforms)) {
      for (const identifier of identifiers) {
        if (lowerText.includes(identifier)) {
          return platform;
        }
      }
    }

    return 'unknown';
  },

  /**
   * Extract booking ID from text
   */
  extractBookingId(text) {
    const matches = [...text.matchAll(this.patterns.bookingId)];
    if (matches.length === 0) return null;

    // Return the longest match (most likely to be the actual booking ID)
    const ids = matches.map((m) => m[1].toUpperCase());
    return ids.sort((a, b) => b.length - a.length)[0];
  },

  /**
   * Extract amount from text
   */
  extractAmount(text) {
    console.log('Extracting amount from text...');
    
    // Method 1: Find line containing "Total Amount" and extract rupee value from it
    const lines = text.split(/[\n\r]+/);
    for (const line of lines) {
      if (/total\s*amount/i.test(line)) {
        console.log('Found Total Amount line:', line);
        // Extract any rupee amount from this line
        const rupeeMatch = line.match(/[₹₨]\s*([0-9,]+(?:\.[0-9]{1,2})?)/);
        if (rupeeMatch) {
          const amount = parseFloat(rupeeMatch[1].replace(/,/g, ''));
          if (!isNaN(amount) && amount > 0) {
            console.log('Extracted Total Amount from line:', amount);
            return amount;
          }
        }
        // Try without rupee symbol - just number after "Total Amount"
        const numMatch = line.match(/total\s*amount.*?([0-9,]+(?:\.[0-9]{1,2})?)/i);
        if (numMatch) {
          const amount = parseFloat(numMatch[1].replace(/,/g, ''));
          if (!isNaN(amount) && amount > 0) {
            console.log('Extracted Total Amount (no symbol):', amount);
            return amount;
          }
        }
      }
    }
    
    // Method 2: Try totalAmountSplit pattern (handles whitespace between label and value)
    this.patterns.totalAmountSplit.lastIndex = 0;
    const splitMatches = [...text.matchAll(this.patterns.totalAmountSplit)];
    if (splitMatches.length > 0) {
      const amounts = splitMatches
        .map((m) => parseFloat(m[1].replace(/,/g, '')))
        .filter((a) => !isNaN(a) && a > 0);
      if (amounts.length > 0) {
        console.log('Found Total Amount (split pattern):', Math.max(...amounts));
        return Math.max(...amounts);
      }
    }
    
    // Method 3: Try original totalAmount pattern
    this.patterns.totalAmount.lastIndex = 0;
    const totalAmountMatches = [...text.matchAll(this.patterns.totalAmount)];
    if (totalAmountMatches.length > 0) {
      const amounts = totalAmountMatches
        .map((m) => parseFloat(m[1].replace(/,/g, '')))
        .filter((a) => !isNaN(a) && a > 0);
      if (amounts.length > 0) {
        console.log('Found Total Amount:', Math.max(...amounts));
        return Math.max(...amounts);
      }
    }
    
    // Method 4: Try other patterns as fallback
    const patterns = [
      this.patterns.amount,
      this.patterns.amountAlt,
      this.patterns.amountRupee,
    ];
    
    let allAmounts = [];
    
    for (const pattern of patterns) {
      // Reset regex lastIndex
      pattern.lastIndex = 0;
      const matches = [...text.matchAll(pattern)];
      const amounts = matches
        .map((m) => parseFloat(m[1].replace(/,/g, '')))
        .filter((a) => !isNaN(a) && a > 0);
      allAmounts = [...allAmounts, ...amounts];
    }
    
    if (allAmounts.length === 0) return null;
    
    // Return the largest amount (likely the total)
    console.log('Using fallback - largest amount:', Math.max(...allAmounts));
    return Math.max(...allAmounts);
  },

  /**
   * Extract date from text
   */
  extractDate(text) {
    const match = text.match(this.patterns.date);
    return match ? match[0] : null;
  },

  /**
   * Extract time from text
   */
  extractTime(text) {
    const match = text.match(this.patterns.time);
    return match ? match[0] : null;
  },

  /**
   * Check if booking ID is already used (duplicate prevention)
   */
  async isBookingIdDuplicate(bookingId, currentRequestId = null) {
    if (!bookingId) return { isDuplicate: false };

    const query = {
      bookingId: bookingId.toUpperCase(),
      status: { $in: ['completed', 'accepted', 'in_progress'] },
    };

    if (currentRequestId) {
      query._id = { $ne: currentRequestId };
    }

    const existing = await Request.findOne(query)
      .select('_id createdAt buyerId')
      .populate('buyerId', 'name');

    if (existing) {
      return {
        isDuplicate: true,
        usedBy: existing.buyerId?.name || 'Another buyer',
        usedAt: existing.createdAt,
      };
    }

    return { isDuplicate: false };
  },

  /**
   * Verify amount matches (with tolerance)
   */
  verifyAmount(extractedAmount, expectedAmount, tolerancePercent = 15) {
    if (!extractedAmount || !expectedAmount) {
      return { matches: null, warning: 'Could not verify amount from screenshot' };
    }

    const tolerance = expectedAmount * (tolerancePercent / 100);
    const matches = Math.abs(extractedAmount - expectedAmount) <= tolerance;

    return {
      matches,
      extracted: extractedAmount,
      expected: expectedAmount,
      difference: Math.abs(extractedAmount - expectedAmount),
      warning: matches
        ? null
        : `Amount mismatch: Screenshot shows ₹${extractedAmount}, expected ₹${expectedAmount}`,
    };
  },

  /**
   * Main verification function - verifies ticket screenshot
   */
  async verifyTicket(imagePath, request) {
    const result = {
      approved: true, // Default to approved
      autoRejected: false, // Only true for duplicate booking ID
      rejectReason: null,
      warnings: [],
      extractedData: {
        bookingId: null,
        amount: null,
        date: null,
        time: null,
        platform: null,
        rawText: null,
      },
      confidence: 0,
    };

    try {
      // Step 1: Extract text from image
      console.log('Starting ticket verification for request:', request._id);
      const { text, confidence } = await this.extractText(imagePath);
      result.confidence = confidence;

      if (!text || text.trim().length < 10) {
        result.warnings.push('Could not read text from screenshot clearly');
        return result; // Still approved, but with warning
      }

      // Step 2: Detect platform
      result.extractedData.platform = this.detectPlatform(text);
      console.log('Detected platform:', result.extractedData.platform);

      // Step 3: Extract data
      result.extractedData.bookingId = this.extractBookingId(text);
      result.extractedData.amount = this.extractAmount(text);
      result.extractedData.date = this.extractDate(text);
      result.extractedData.time = this.extractTime(text);
      result.extractedData.rawText = text.substring(0, 500); // Store first 500 chars

      console.log('Extracted data:', {
        bookingId: result.extractedData.bookingId,
        amount: result.extractedData.amount,
        date: result.extractedData.date,
        platform: result.extractedData.platform,
      });

      // Step 4: CRITICAL CHECK - Duplicate Booking ID
      if (result.extractedData.bookingId) {
        const duplicateCheck = await this.isBookingIdDuplicate(
          result.extractedData.bookingId,
          request._id
        );

        if (duplicateCheck.isDuplicate) {
          // AUTO-REJECT - This is the only case we reject automatically
          result.approved = false;
          result.autoRejected = true;
          result.rejectReason = `This ticket has already been used by ${duplicateCheck.usedBy}`;
          console.log('Duplicate booking ID detected:', result.extractedData.bookingId);
          return result;
        }
      } else {
        result.warnings.push('Could not extract booking ID from screenshot');
      }

      // Step 5: Amount verification (warning only, not rejection)
      const amountCheck = this.verifyAmount(
        result.extractedData.amount,
        request.originalPrice || request.finalAmount
      );
      if (amountCheck.warning) {
        result.warnings.push(amountCheck.warning);
      }

      // Step 6: Low confidence warning
      if (confidence < 50) {
        result.warnings.push(
          `Low OCR confidence (${Math.round(confidence)}%). Screenshot quality may be poor.`
        );
      }

      console.log('Verification complete. Approved:', result.approved, 'Warnings:', result.warnings.length);

      return result;
    } catch (error) {
      console.error('Ticket verification error:', error);
      result.warnings.push('Automated verification encountered an error');
      return result; // Still approved with warning
    }
  },

  /**
   * Quick test function for OCR (for development/testing)
   */
  async testOCR(imagePath) {
    try {
      const { text, confidence } = await this.extractText(imagePath);
      
      return {
        success: true,
        text,
        confidence,
        extracted: {
          bookingId: this.extractBookingId(text),
          amount: this.extractAmount(text),
          date: this.extractDate(text),
          time: this.extractTime(text),
          platform: this.detectPlatform(text),
        },
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
      };
    }
  },
};

module.exports = ticketVerificationService;
