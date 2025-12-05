import { Module, Global } from '@nestjs/common';
import { AiAnalysisService } from './ai-analysis.service';

// 💡 نستخدم @Global() لجعل هذه الوحدة متاحة تلقائياً لأي وحدة أخرى في التطبيق
// لكن يفضل عدم استخدامها إلا للوحدات الأساسية جداً، لذا سنتركها بدون @Global() حالياً.

@Module({
  // نضيف الخدمة لقائمة الـ Providers
  providers: [AiAnalysisService],
  // نصدر الخدمة لتمكين الوحدات الأخرى من حقنها (Injection)
  exports: [AiAnalysisService],
})
export class AiAnalysisModule {}