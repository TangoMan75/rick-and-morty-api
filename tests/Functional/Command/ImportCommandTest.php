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

use Symfony\Bundle\FrameworkBundle\Console\Application;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;
use Symfony\Component\Console\Tester\CommandTester;

class ImportCommandTest extends KernelTestCase
{
    public function testExecuteWithValidJsonFile(): void
    {
        $kernel = self::bootKernel();
        $application = new Application($kernel);

        $command = $application->find('app:import');
        $commandTester = new CommandTester($command);

        $jsonData = [
            [
                'id'       => 1,
                'name'     => 'Test Character',
                'status'   => 'Alive',
                'species'  => 'Human',
                'type'     => '',
                'gender'   => 'Male',
                'origin'   => ['name' => 'Earth', 'url' => 'https://rickandmortyapi.com/api/location/1'],
                'location' => ['name' => 'Earth', 'url' => 'https://rickandmortyapi.com/api/location/1'],
                'image'    => 'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
                'episode'  => ['https://rickandmortyapi.com/api/episode/1'],
                'url'      => 'https://rickandmortyapi.com/api/character/1',
                'created'  => '2017-11-04T18:48:46.250Z',
            ],
        ];

        $tempFile = sys_get_temp_dir().'/characters.json';
        file_put_contents($tempFile, json_encode($jsonData));

        $commandTester->execute([
            'file' => $tempFile,
        ]);

        $commandTester->assertCommandIsSuccessful();
        $output = $commandTester->getDisplay();
        $this->assertStringContainsString('Imported 1 characters successfully', $output);

        unlink($tempFile);
    }

    public function testExecuteWithMissingFile(): void
    {
        $kernel = self::bootKernel();
        $application = new Application($kernel);

        $command = $application->find('app:import');
        $commandTester = new CommandTester($command);

        $commandTester->execute([
            'file' => '/nonexistent/file.json',
        ]);

        $this->assertEquals(1, $commandTester->getStatusCode());
        $output = $commandTester->getDisplay();
        $this->assertStringContainsString('File not found: file.json', $output);
    }

    public function testExecuteWithInvalidJson(): void
    {
        $kernel = self::bootKernel();
        $application = new Application($kernel);

        $command = $application->find('app:import');
        $commandTester = new CommandTester($command);

        $tempFile = sys_get_temp_dir().'/invalid.json';
        file_put_contents($tempFile, '{invalid json}');

        $commandTester->execute([
            'file' => $tempFile,
        ]);

        $this->assertEquals(1, $commandTester->getStatusCode());
        $output = $commandTester->getDisplay();
        $this->assertStringContainsString('Invalid JSON format', $output);

        unlink($tempFile);
    }

    public function testExecuteWithUnknownEntityType(): void
    {
        $kernel = self::bootKernel();
        $application = new Application($kernel);

        $command = $application->find('app:import');
        $commandTester = new CommandTester($command);

        $tempFile = sys_get_temp_dir().'/unknown.json';
        file_put_contents($tempFile, '[]');

        $commandTester->execute([
            'file' => $tempFile,
        ]);

        $this->assertEquals(1, $commandTester->getStatusCode());
        $output = $commandTester->getDisplay();
        $this->assertStringContainsString('Cannot determine entity type from filename', $output);

        unlink($tempFile);
    }
}
