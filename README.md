# 🧑‍🚀 The Rick and Morty API Redesign: Building a Headless Backend with PHP, Symfony, and API Platform

|           | ⏲️ **Time Spent on Technical Test:** |
|-----------|--------------------------------------|
| Wednesday | 8 hours                              |
| Thursday  | 4 hours                              |
| Friday    | 6 hours                              |
| Saturday  | 1 hour                               |
| Monday    | 8 hours                              |
| Tuesday   | 8 hours                              |
| Total     | 35 hours                             |

## 📝 The Challenge: A Rick and Morty API Clone

> Based on the documentation available here: https://rickandmortyapi.com/documentation, redevelop part of the Rick&Morty API.
> The API must be developed with PHP Symfony and the deliverable must be on a Git repository.
> Candidates will be judged on the quality of the code and tests provided.
> The candidate is free to choose their libraries for developing the API and tests as long as they are within the Symfony ecosystem.
> There is no time limit on the technical test and no obligation to develop the entire API, but the candidate must indicate the time spent on the technical test.

---

## 🏗️ Architecture Overview

- **Backend:** **Symfony 7.4** for the framework foundation, **API Platform 4.2** for API management (API Platform is not yet fully compatible with Symfony 8).
- **Database:** I opted for **SQLite** to keep the local setup extremely simple and fast, minimizing external dependencies.
- **Containerization:** **Docker, docker-compose and Traefik** for an easy, portable environment setup.
- **Core Entities:** I focused on mirroring the core data models:
  - `Character`
  - `Location`
  - `Episode`
- **Import/Export Command:** Custom command to import/export the data as json.
- **Data Scraper:** A custom **`RickAndMortyClient`** was designed to scrape and store the initial dataset from the official API.
- **Fixtures:** A set of fixtures is provided for **Doctrine/DataFixtures**.
- **CI/CD:** Core business logic is covered with **PHPUnit** unit tests.
  - **Linter:** Code style is enforced with **PHP-CS-Fixer**.
  - **GitHub actions**: Tests and lint checks are executed on every push/merge.

### 🔗 The Original API

For reference, here are the links to the original project:

- **Documentation:** [https://rickandmortyapi.com](https://rickandmortyapi.com)
- **Source Code:** [https://github.com/afuh/rick-and-morty-api](https://github.com/afuh/rick-and-morty-api)

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/tangoman75/rick-and-morty-api.git
```

### 2.1 Run Container (Recommended)

Assuming you have Docker and Docker Compose on your local machine.

```bash
make up
```

The API will be available at `http://{container_ip}`.

### 2.2 Run Locally (Alternative Method)

Assuming you have PHP 8.2 installed locally

- **Install dependencies:**
 ```bash
 make install
 ```
- **Import Data:**
 ```bash
 make import_data
 ```
- **Start Application:**
 ```bash
 make serve
 ```

The API will be available at `http://127.0.0.1:8000`.

### 2.3 🔀 Setting up Traefik Locally (Optional)

You can use [TangoMan75/traefik](https://github.com/TangoMan75/traefik) repository as reverse proxy.

1. **Clone the Traefik repository:**
  ```bash
  git clone https://github.com/TangoMan75/traefik.git
  cd traefik
  echo "DOMAINS=\"rick-and-morty-api traefik whoami\"" > .env
  make up
  ```

2. **Follow the Traefik setup instructions**.

3. **Run the Rick And Morty API Container**.
  ```bash
  cd rick-and-morty-api
  make up
  ```
  Rick And Morty API container already has appropriate labels for Traefik routing.

4. **Access the API** through Traefik at the configured domain
  - The API will be available at `http://rick-and-morty-api.localhost`.

This setup allows you to manage multiple services behind a single reverse proxy for a more realistic development environment.

## 🔧 Usage

You can use the following endpoints to interact with the API:

- `/api/characters`: Returns a list of all characters.
- `/api/characters/{id}`: Returns a single character by ID.
- `/api/episodes`: Returns a list of all episodes.
- `/api/episodes/{id}`: Returns a single episode by ID.
- `/api/locations`: Returns a list of all locations.
- `/api/locations/{id}`: Returns a single location by ID.

You can also use the API documentation to explore the available endpoints and their parameters.
The documentation is available at `http://127.0.0.1:8000/api/docs`.

## 🚀 Extra Features : Scraper, Import and Export Commands

The project includes several Symfony console commands for managing data:

### 🌐 Scrape Data from API

To scrape and import data directly from the official Rick and Morty API:

```bash
php bin/console app:scrape
```

This command will fetch all locations, episodes, and characters from the API and store them in the database.

### 📥 Import Data from JSON

To import data from a JSON file:

```bash
php bin/console app:import <file>
```

Where `<file>` is the path to the JSON file. Supported files are `characters.json`, `episodes.json`, and `locations.json`.

Example:

```bash
php bin/console app:import data/characters.json
```

### 📤 Export Data to JSON

To export data from the database to a JSON file:

```bash
php bin/console app:export <entityType> [outputFile]
```

- `<entityType>`: The entity type to export (Character, Episode, Location).
- `[outputFile]`: Optional path to the output file. Defaults to `data/{entityType}.json`.

Examples:

```bash
php bin/console app:export Character
php bin/console app:export Episode data/episodes_backup.json
php bin/console app:export Location
```

This will export all entities of the specified type to the JSON file.

## 📏 Conventions

### 🎨 Code Style

The project follows the PSR-12 coding standard, which is enforced by PHP-CS-Fixer.

### 🧪 Testing

The project uses PHPUnit for testing. The tests are located in the `tests/` directory, and are organized into three categories:

- **Unit:** for testing individual classes
- **Integration:** for testing the integration between different parts of the application
- **Functional:** for testing the application as a whole

## 🛠️ Development Commands

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

