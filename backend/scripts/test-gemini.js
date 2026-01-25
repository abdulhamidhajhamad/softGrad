// Quick test script for Gemini API connection
const { GoogleGenAI } = require('@google/genai');

const apiKey = 'AIzaSyAnG3Hph4pCUvGXqYGaELKa_-9D4jVZ5Cw';

async function testGemini() {
  try {
    console.log('🔌 Testing Gemini API connection...');
    
    const ai = new GoogleGenAI({ apiKey });
    
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: 'Say "Hello, I am working!" in one line.',
    });
    
    console.log('✅ Gemini Response:', response.text);
    
  } catch (error) {
    console.error('❌ Gemini Error:', error.message);
    console.error('Full error:', error);
  }
}

testGemini();
