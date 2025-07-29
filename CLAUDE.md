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