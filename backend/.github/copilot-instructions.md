# Copilot Instructions for AI Coding Agents

## Big Picture Architecture
- **Backend:** Built with NestJS (TypeScript). Organized by domain modules (e.g., `admin`, `auth`, `booking`, `ai-analysis`, etc.) in [src/](backend/src/).
- **AI Services:** Python-based, located in [AiService/](backend/AiService/). Includes recommender systems and utility scripts.
- **Frontend:** Flutter app in [frontend/flutter_application_1/](frontend/flutter_application_1/).
- **Public Assets:** Static files for web/Flutter in [public/](backend/public/).
- **Config:** Secrets and keys in [config/](backend/config/).

## Developer Workflows
- **Install dependencies:**
  - Node: `npm install` in [backend/](backend/)
  - Python: `pip install -r requirements.txt` in [backend/AiService/](backend/AiService/)
- **Run backend:**
  - Development: `npm run start:dev`
  - Production: `npm run start:prod`
- **Run tests:**
  - Unit: `npm run test`
  - E2E: `npm run test:e2e`
- **Run AI service:**
  - `python main.py` in [backend/AiService/](backend/AiService/)

## Project-Specific Patterns & Conventions
- **NestJS modules:** Each domain (e.g., `admin`, `auth`, `booking`) has its own controller, service, entity/schema, and module file.
- **Guards & Decorators:** Custom guards (e.g., `admin.guard.ts`, `jwt-auth.guard.ts`) and decorators (e.g., `roles.decorator.ts`, `user.decorator.ts`) for authorization.
- **Entities/Schemas:** Data models are defined as `.entity.ts` or `.schema.ts` files per domain.
- **AI Integration:** Backend communicates with Python AI services via scripts in [AiService/](backend/AiService/).
- **Config Management:** Sensitive keys in [config/firebase-key.json](backend/config/firebase-key.json).

## Integration Points
- **Firebase:** Used for authentication/config (see [config/firebase-key.json](backend/config/firebase-key.json)).
- **AI Service:** Python scripts for recommendations and analysis (see [backend/AiService/model/recommender.py](backend/AiService/model/recommender.py)).
- **Flutter Frontend:** Consumes backend APIs and static assets.

## Examples
- To add a new domain, create a folder in [src/](backend/src/) with `*.controller.ts`, `*.service.ts`, `*.entity.ts`, and `*.module.ts`.
- For new AI features, add Python scripts in [AiService/model/](backend/AiService/model/) and expose via [main.py](backend/AiService/main.py).
- For new config, update [config/](backend/config/).

## References
- [backend/README.md](backend/README.md): For build/test commands and project overview.
- [src/](backend/src/): For backend structure and conventions.
- [AiService/](backend/AiService/): For AI integration patterns.
- [frontend/flutter_application_1/](frontend/flutter_application_1/): For Flutter app structure.

---
**Update this file if major architecture, workflow, or integration changes occur.**
