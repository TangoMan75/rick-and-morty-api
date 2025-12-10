Feature: Import JSON data into the database from the terminal
  As a developer
  I want a Symfony Console command that loads a JSON file into the database
  So that I can quickly populate entities with structured data

  Background:
    Given valid Doctrine entities "Character", "Episode", and "Location" exist
    And the database is empty

  Scenario: Successful import of a valid JSON file
    Given a JSON file "characters.json" containing valid character data
    When I run the command "app:import data/characters.json"
    Then the command should finish successfully
    And the database should contain all characters from the file
    And the console should display "Imported 20 characters successfully"

  Scenario: Import fails with invalid JSON
    Given a JSON file "invalid.json" containing malformed JSON
    When I run the command "app:import data/invalid.json"
    Then the command should fail
    And the console should display an error message "Invalid JSON format"

  Scenario: Import fails with missing file
    Given no file exists at path "missing.json"
    When I run the command "app:import data/missing.json"
    Then the command should fail
    And the console should display "File not found: missing.json"

  Scenario: Import handles partial failures
    Given a JSON file "mixed.json" containing some valid and some invalid character entries
    When I run the command "app:import data/mixed.json"
    Then the command should finish with warnings
    And the database should contain only the valid characters
    And the console should display "Imported 7 items, 3 failed"

  Scenario: Import episodes and characters
    Given a JSON file "characters.json" containing valid character data
    And a JSON file "episodes.json" containing episodes referencing those characters
    When I run the command "app:import data/characters.json"
    And I run the command "app:import data/episodes.json"
    Then both commands should finish successfully
    And the database should contain all characters and episodes
    And all episode-character relations should be correctly established
    And the console should display "Imported 20 characters successfully"
    And the console should display "Imported 20 episodes successfully"

  Scenario: Import characters with origin and location relationships
    Given a JSON file "locations.json" containing valid location data
    And a JSON file "characters.json" containing valid character data with location relationships
    When I run the command "app:import data/locations.json"
    And I run the command "app:import data/characters.json"
    Then the commands should finish successfully
    And the database should contain all locations and characters from the files
    And character origin and location relationships should be set