# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a full-stack application consisting of two separate codebases:

- **snaproom-laravel/** - Laravel API backend implementing ADR (Action-Domain-Responder) pattern
- **snaproom-react/** - React frontend using Feature-Sliced Design (FSD) architecture with TypeScript

Both projects maintain their own CLAUDE.md files with specific guidance, but this root file provides coordination between them.

## Development Commands

### Starting Both Applications
```bash
# Terminal 1 - Start Laravel backend
cd snaproom-laravel
composer dev  # Starts server, queue, logs, and vite concurrently

# Terminal 2 - Start React frontend
cd snaproom-react
npm start     # Starts on port 3000
```

### Laravel Backend (snaproom-laravel/)
- `composer dev` - Complete development environment (server, queue, logs, vite)
- `php artisan serve` - API server only on http://localhost:8000
- `php artisan test` - Run all tests
- `composer test` - Run tests with config clearing
- `./vendor/bin/pint` - Code formatting

### React Frontend (snaproom-react/)
- `npm start` - Development server on port 3000
- `npm run build` - Production build
- `npm test` - Test suite
- `npm run lint` - ESLint checking
- `npm run lint:fix` - Auto-fix ESLint issues

## Architecture Overview

### Full-Stack Communication Pattern

The application follows a **decoupled API-first architecture**:

1. **Laravel Backend** exposes RESTful API endpoints at `/api/*`
2. **React Frontend** consumes these APIs through a shared API client
3. **Authentication** handled via token-based approach (likely JWT)
4. **CORS** configured to allow React frontend to communicate with Laravel API

### Backend Architecture (ADR Pattern)

Laravel implements **Action-Domain-Responder** pattern:
- **Actions** (`app/Actions/`) - Input validation and preprocessing
- **Domain Services** (`app/Domain/`) - Business logic and operations  
- **Responders** (`app/Responders/`) - Response formatting and structure
- **Controllers** extend `ADRController` for consistent API responses

### Frontend Architecture (Feature-Sliced Design)

React follows **FSD methodology** with strict layer hierarchy:
- **app/** - Global setup, routing, providers
- **pages/** - Route components  
- **widgets/** - Complex reusable UI blocks
- **features/** - User functionality (auth, forms)
- **entities/** - Business domain models (user, etc.)
- **shared/** - Generic reusable code (UI kit, API client)

## Cross-Project Development Guidelines

### API Integration
- **Base URL**: Laravel serves API at `http://localhost:8000/api/`
- **Authentication**: Token-based (check `src/shared/api/` in React project)
- **Response Format**: Standardized JSON structure from Laravel responders
- **Error Handling**: Consistent error responses from Laravel ADR pattern

### Data Flow
1. React components trigger API calls via `shared/api/`
2. Laravel routes (`routes/api.php`) map to ADR controllers
3. Controllers coordinate Actions → Domain Services → Responders
4. Responses flow back through React's feature layers

### Development Workflow
1. **API-First Development**: Define Laravel API endpoints first
2. **Type Safety**: Use TypeScript interfaces in React matching Laravel responses
3. **Feature Parity**: Maintain corresponding features across both codebases
4. **Testing**: Test API endpoints in Laravel, integration in React

## Common Development Patterns

### Adding New Features
1. **Laravel Side**:
   - Create Action, Domain Service, Responder in respective directories
   - Add Controller extending `ADRController`
   - Define routes in `routes/api.php`
   - Write tests in `tests/Feature/`

2. **React Side**:
   - Follow FSD layer structure
   - Create API calls in appropriate `api/` segment
   - Define TypeScript interfaces matching Laravel responses
   - Build UI components following existing patterns

### Authentication Flow
- Laravel handles auth via Actions/Domain/Responders pattern
- React manages auth state in `features/auth/` with `entities/user/`
- Token stored and managed through `shared/api/` client
- Auth widget combines feature + entity for complete UI

### Database Considerations
- **Laravel**: PostgreSQL primary, SQLite for testing
- **Migrations**: Standard Laravel migrations in `database/migrations/`
- **Seeders**: Test data via `database/seeders/`
- **React**: No direct database access, only via Laravel API

## Technology Stack

### Backend (Laravel)
- **Framework**: Laravel 12.x with PHP 8.2+
- **Architecture**: ADR pattern with dependency injection
- **Database**: PostgreSQL (production), SQLite (testing)
- **Testing**: PHPUnit with Feature/Unit test structure
- **Code Style**: Laravel Pint (PSR-12)

### Frontend (React)
- **Framework**: React 18.2+ with TypeScript 4.9+
- **Architecture**: Feature-Sliced Design methodology
- **Routing**: React Router v6
- **Testing**: React Testing Library + Jest
- **Code Style**: ESLint with React/TypeScript rules

## Project Coordination

### Environment Setup
Both projects should be running simultaneously during development:
- Laravel API provides backend services on port 8000
- React frontend consumes API and serves UI on port 3000
- Hot reloading enabled in both environments

### Debugging Cross-Project Issues
1. Check Laravel logs: `storage/logs/laravel.log` or `php artisan pail`
2. Check React console for frontend errors
3. Verify API endpoints in Laravel routes and React API client
4. Ensure CORS configuration allows React → Laravel communication
5. Validate data flow through ADR pattern and FSD layers

## Documentation Guidelines

### GitHub Wiki Management

This project uses **GitHub Wiki for comprehensive technical documentation** with the following principles:

#### Wiki Structure & Organization
```
snaproom.wiki/
├── Home.md (프로젝트 전체 개요)
├── 01-프로젝트-가이드/
│   ├── React-Snaproom-React/
│   ├── Laravel-Snaproom-Laravel/  
│   ├── Infrastructure-Snaproom-Infrastructure/
│   └── Monitoring-Snaproom-Monitoring/
├── 02-기술-스택-가이드/
│   ├── React-TypeScript-FSD/
│   ├── Laravel-ADR-Pattern/
│   ├── Docker-Compose-MSA/
│   └── Prometheus-Grafana-Stack/
├── 03-개념-정리/
│   ├── MSA-Architecture-Concepts/
│   ├── Monitoring-Observability-Concepts/
│   └── DevOps-CICD-Concepts/
└── 04-기술-포트폴리오/
    ├── 기술적-의사결정-사례/
    ├── 문제-해결-경험/
    └── 아키텍처-설계-경험/
```

#### Wiki Documentation Standards
- **언어**: 모든 Wiki 문서는 **한국어**로 작성
- **대상**: 이직 준비 및 기술 포트폴리오 활용 가능한 수준의 상세함
- **구조**: 개념 → 실제 구현 → 의사결정 근거 → 문제 해결 → 성과 측정
- **기술적 깊이**: 초급자 이해 + 면접관 설득 가능한 전문성 수준

#### 각 기술별 문서 구성 요소
1. **개념 및 원리**: 기술의 핵심 개념과 동작 원리
2. **선택 근거**: 왜 이 기술을 선택했는지 (비교 분석 포함)
3. **구현 상세**: 실제 프로젝트에서의 구체적 적용 방법
4. **문제 해결**: 발생한 문제와 해결 과정 (트러블슈팅)
5. **성과 및 개선**: 도입 후 측정 가능한 성과와 개선 사항
6. **확장 계획**: 향후 개선 및 확장 방향

#### Wiki 작성 가이드라인
- **제목 규칙**: `[카테고리] 제목` 형식 (예: `[Backend] Laravel ADR 패턴 구현`)
- **내용 구조**: 개요 → 상세 내용 → 코드 예제 → 참조 자료
- **코드 예제**: 실제 동작하는 코드 스니펫 포함
- **시각 자료**: 아키텍처 다이어그램, 플로우차트 등 적극 활용
- **참조 자료**: 공식 문서, 베스트 프랙티스 자료 링크 포함

#### 이직 포트폴리오 연동
- **기술적 의사결정**: 각 기술 선택의 배경과 근거
- **문제 해결 능력**: 실제 마주한 기술적 도전과 해결 과정
- **아키텍처 설계**: 시스템 설계 철학과 구현 방법
- **성장 과정**: 프로젝트를 통한 기술적 성장과 학습

#### 문서 관리 경로
- **Wiki 문서 위치**: `snaproom.wiki/` 디렉토리
- **기존 document/ 폴더**: 사용 중단, 모든 문서는 snaproom.wiki로 이전 완료
- **접근 방법**: GitHub Wiki UI 또는 로컬 snaproom.wiki/ 디렉토리 직접 편집

#### 문서 업데이트 원칙
- **실시간 반영**: 코드 변경 시 관련 Wiki 문서 즉시 업데이트
- **버전 관리**: 주요 변경사항은 버전별로 기록
- **피드백 반영**: 팀 리뷰 및 실무 경험을 통한 지속적 개선
- **품질 관리**: 기술적 정확성과 실무 적용 가능성 중심의 품질 검토