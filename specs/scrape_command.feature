Feature: Scrape Command
  As a developer
  I want to import JSON data into the database from the terminal
  So that I can populate the application with data from RickAndMortyApiClient.php

  Background:
    Given the RickAndMortyApiClient.php is available
    And the database connection is configured

  Scenario: Run scrape command to import JSON data
    When I execute the command "php bin/console app:scrape"
    Then the RickAndMortyApiClient.php should fetch JSON data
    And the data should be parsed successfully
    And the parsed data should be inserted into the database
    And I should see a confirmation message "Data imported successfully"

  Scenario: Handle invalid JSON response
    Given the RickAndMortyApiClient.php returns invalid JSON
    When I execute the command "php bin/console app:scrape"
    Then the command should log an error "Invalid JSON response"
    And no data should be imported into the database

  Scenario: Handle database connection failure
    Given the database connection is not available
    When I execute the command "php bin/console app:scrape"
    Then the command should log an error "Database connection failed"
    And no data should be imported
