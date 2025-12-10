# Project Overview

This project is a headless backend API for the Rick and Morty universe, built with PHP, Symfony, and API Platform. It's a clone of the public Rick and Morty API, with a focus on code quality and testing.

## Technologies

- **Backend:** Symfony 7.4, API Platform 4.2
- **Database:** SQLite
- **Containerization:** Docker
- **Testing:** PHPUnit
- **Linting:** PHP-CS-Fixer

## Architecture

The project follows a standard Symfony architecture. The core of the application is the API, which is built on top of API Platform. The data is stored in a SQLite database, and the application is containerized with Docker.

The core entities are:

- `Character`
- `Location`
- `Episode`

## Getting Started

1.  **Clone the repository:**
  ```bash
  git clone https://github.com/tangoman75/rick-and-morty.git
  ```
2.  **Install dependencies:**
  ```bash
  make install
  ```
3.  **Start the application:**
  ```bash
  make serve
  ```

The API will be available at `http://127.0.0.1:8000/api`.

## Usage

The API is available at `http://127.0.0.1:8000/api`. You can use the following endpoints to interact with the API:

- `/api/characters`: Returns a list of all characters.
- `/api/characters/{id}`: Returns a single character by ID.
- `/api/episodes`: Returns a list of all episodes.
- `/api/episodes/{id}`: Returns a single episode by ID.
- `/api/locations`: Returns a list of all locations.
- `/api/locations/{id}`: Returns a single location by ID.

You can also use the API documentation to explore the available endpoints and their parameters. The documentation is available at `http://127.0.0.1:8000/api/docs`.

## Conventions

### Code Style

The project follows the PSR-12 coding standard, which is enforced by PHP-CS-Fixer.

### Testing

The project uses PHPUnit for testing. The tests are located in the `tests/` directory, and are organized into three categories:

- **Unit:** for testing individual classes
- **Integration:** for testing the integration between different parts of the application
- **Functional:** for testing the application as a whole

## Development Commands

This project uses a `Makefile` to provide a set of useful commands for managing the project. The following are some of the most important commands:

- **Install**: `make install` (composer install, create DB, set env, clear cache)
- **Lint check**: `make lint` (PHP CS Fixer dry-run)
- **Lint fix**: `make lint_fix` (PHP CS Fixer fix)
- **All tests**: `make tests` (unit + integration + functional)
- **Unit tests**: `make tests_unit`
- **Integration tests**: `make tests_integration`
- **Functional tests**: `make tests_functional`
- **Single test**: `make tests_unit file=tests/Unit/SomeTest.php` (or integration/functional)
- **Coverage**: `make coverage`
