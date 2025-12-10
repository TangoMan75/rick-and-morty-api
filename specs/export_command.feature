Feature: Export database data to JSON files from the terminal
  As a developer
  I want a Symfony Console command that exports database entities to JSON files
  So that I can backup or share structured data

  Background:
    Given valid Doctrine entities "Character", "Episode", and "Location" exist
    And the database contains sample data

   Scenario: Successful export of characters to JSON file
     When I run the command "app:export Character"
     Then the command should finish successfully
     And a JSON file "data/characters.json" should be created
     And the file should contain all characters from the database
     And the console should display "Exported 1 characters successfully"

  Scenario: Export fails with invalid entity type
    When I run the command "app:export InvalidEntity"
    Then the command should fail
    And the console should display an error message "Entity 'InvalidEntity' not found"

   Scenario: Export fails with no data in database
     Given the database is empty
     When I run the command "app:export Character"
     Then the command should finish successfully
     And the console should display "Exported 0 characters successfully"
     And a JSON file "data/characters.json" should be created
     And the JSON file should contain an empty array

   Scenario: Export episodes to JSON file
     When I run the command "app:export Episode"
     Then the command should finish successfully
     And a JSON file "data/episodes.json" should be created
     And the file should contain all episodes from the database
     And the console should display "Exported 1 episodes successfully"

   Scenario: Export locations to JSON file
     When I run the command "app:export Location"
     Then the command should finish successfully
     And a JSON file "data/locations.json" should be created
     And the file should contain all locations from the database
     And the console should display "Exported 1 locations successfully"

   Scenario: Export fails with write permission error
     Given the output directory is not writable
     When I run the command "app:export Character /readonly/characters.json"
     Then the command should fail
     And the console should display "Failed to write to file: /readonly/characters.json"
