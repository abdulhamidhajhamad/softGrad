import { Injectable, Logger } from '@nestjs/common';
import { GoogleGenAI } from '@google/genai'; 

// واجهة البيانات التي يتوقعها التطبيق من الـ AI
export interface AiAnalysisUpdate {
  score: number; 
  tags: string[]; 
  bestFor: string[]; 
}

@Injectable()
export class AiAnalysisService {
  private readonly logger = new Logger(AiAnalysisService.name);
  private readonly ai: GoogleGenAI;

  constructor() {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      this.logger.error('GEMINI_API_KEY is not set in environment variables.');
      throw new Error('AI Service failed to initialize due to missing API Key.');
    }
    
    this.ai = new GoogleGenAI({ apiKey }); 
  }

  /**
   * 🧠 يقوم بتحليل تقييم جديد واستخلاص البيانات المحدثة.
   * @param serviceId ID of the service being reviewed.
   * @param newReviewComment The new comment text.
   * @param existingReviews A summary or array of past reviews (for better context).
   * @returns The updated analysis object.
   * @throws Error إذا فشل الاتصال أو كان الرد غير صالح.
   */
  async analyzeReview(
    serviceId: string,
    newReviewComment: string,
    existingReviews: string[] = [],
  ): Promise<AiAnalysisUpdate> {
    this.logger.log(`Starting AI analysis for Service ID: ${serviceId}`);

    // الـ Prompt الهندسي لـ Gemini
    const prompt = `
      You are an expert event service analyst. Your task is to analyze a new service review 
      and generate an updated sentiment score and descriptive tags for the service.
      
      NEW REVIEW: "${newReviewComment}"
      
      EXISTING CONTEXT: ${existingReviews.length > 0 ? 'Past reviews are: ' + existingReviews.join('; ') : 'No previous detailed context provided.'}
      
      Based SOLELY on the new review and its sentiment:
      1. Determine the sentiment score (0.0 for extremely negative, 1.0 for extremely positive).
      2. Extract 2-3 key tags that describe the service's quality (e.g., 'Excellent Staff', 'Loud Music', 'Great Value').
      3. Classify the likely event types this service is BEST suited for (e.g., 'birthday', 'wedding', 'corporate').

      Return the result as a raw JSON object ONLY, adhering to the following interface:
      {
        "score": number,
        "tags": string[],
        "bestFor": string[]
      }
    `;

    try {
      const response = await this.ai.models.generateContent({
        // 🛑 التعديل هنا: استخدام النموذج الأكثر استقرارًا gemini-2.5-flash
        model: 'gemini-2.5-flash', 
        contents: prompt,
        config: {
          responseMimeType: "application/json",
          responseSchema: {
            type: "object",
            properties: {
              score: { type: "number", description: "Sentiment score from 0.0 to 1.0" },
              tags: { type: "array", items: { type: "string" }, description: "2-3 key descriptive tags" },
              bestFor: { type: "array", items: { type: "string" }, description: "Classified event types" }
            },
            required: ["score", "tags", "bestFor"]
          }
        }
      });

      if (!response || !response.text) {
          this.logger.error(`Gemini returned empty response for ${serviceId}. Prompt used: ${prompt.substring(0, 100)}...`);
          throw new Error('Gemini API returned an empty or invalid text response.');
      }
      
      const jsonText = response.text.trim();
      const actualResult: AiAnalysisUpdate = JSON.parse(jsonText);
      
      this.logger.log(`AI Analysis Complete for ${serviceId}. Score: ${actualResult.score.toFixed(2)}`);
      
      return actualResult;

    } catch (error) {
      this.logger.error(`Gemini API Error for ${serviceId}:`, error);
      // 💡 تسجيل رسالة الخطأ الواردة من API
      const errorMessage = error.message.includes('ApiError') ? JSON.stringify(error.message) : error.message;
      throw new Error(`AI Analysis failed due to API error: ${errorMessage}`);
    }
  }
}