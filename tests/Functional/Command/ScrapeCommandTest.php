<?php

declare(strict_types=1);

/*
 * This file is part of the TangoMan package.
 *
 * (c) "Matthias Morin" <mat@tangoman.io>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

namespace App\Tests\Functional\Command;

use App\Client\RickAndMortyApiClient;
use Symfony\Bundle\FrameworkBundle\Console\Application;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;
use Symfony\Component\Console\Tester\CommandTester;

class ScrapeCommandTest extends KernelTestCase
{
    public function testExecuteSuccessfulScrape(): void
    {
        // Mock the client to avoid actual HTTP calls
        $mockClient = $this->createMock(RickAndMortyApiClient::class);
        $mockClient->method('getLocationCount')->willReturn(1);
        $mockClient->method('getEpisodeCount')->willReturn(1);
        $mockClient->method('getCharacterCount')->willReturn(1);
        $mockClient->expects($this->once())->method('importLocations');
        $mockClient->expects($this->once())->method('importEpisodes');
        $mockClient->expects($this->once())->method('importCharacters');

        $kernel = self::bootKernel();
        // Replace the service in the container
        $kernel->getContainer()->set(RickAndMortyApiClient::class, $mockClient);

        $application = new Application($kernel);

        $command = $application->find('app:scrape');
        $commandTester = new CommandTester($command);

        $commandTester->execute([]);

        $commandTester->assertCommandIsSuccessful();
        $output = $commandTester->getDisplay();
        $this->assertStringContainsString('Data imported successfully', $output);
    }

    public function testExecuteWithClientException(): void
    {
        // Mock the client to throw an exception
        $mockClient = $this->createMock(RickAndMortyApiClient::class);
        $mockClient->method('getLocationCount')->willThrowException(new \Exception('API error'));

        $kernel = self::bootKernel();
        $kernel->getContainer()->set(RickAndMortyApiClient::class, $mockClient);

        $application = new Application($kernel);

        $command = $application->find('app:scrape');
        $commandTester = new CommandTester($command);

        $commandTester->execute([]);

        $this->assertEquals(1, $commandTester->getStatusCode());
        $output = $commandTester->getDisplay();
        $this->assertStringContainsString('Database connection failed', $output);
    }
}
