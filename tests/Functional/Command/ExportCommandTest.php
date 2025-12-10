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

use App\Entity\Character;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Console\Application;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;
use Symfony\Component\Console\Tester\CommandTester;

class ExportCommandTest extends KernelTestCase
{
    private EntityManagerInterface $em;

    protected function setUp(): void
    {
        parent::setUp();
        $this->em = self::getContainer()->get(EntityManagerInterface::class);
        // Clear existing characters
        $this->em->createQuery('DELETE FROM App\Entity\Character')->execute();
        $this->em->createQuery('DELETE FROM App\Entity\Episode')->execute();
        $this->em->createQuery('DELETE FROM App\Entity\Location')->execute();
    }

    public function testExecuteWithValidEntityType(): void
    {
        // Create a test character
        $character = new Character();
        $character->setId(999);
        $character->setName('Test Character');
        $character->setStatus('Alive');
        $character->setSpecies('Human');
        $character->setType('');
        $character->setGender('Male');
        $character->setImage('https://example.com/image.jpg');
        $character->setUrl('https://example.com/character/1');
        $character->setCreated(new \DateTime());

        $this->em->persist($character);
        $this->em->flush();

        $kernel = self::bootKernel();
        $application = new Application($kernel);

        $command = $application->find('app:export');
        $commandTester = new CommandTester($command);

        $tempFile = tempnam(sys_get_temp_dir(), 'test_export');
        unlink($tempFile); // Remove the file, we'll create it
        $tempFile .= '.json';

        $commandTester->execute([
            'entityType' => 'Character',
            'outputFile' => $tempFile,
        ]);

        $commandTester->assertCommandIsSuccessful();
        $output = $commandTester->getDisplay();
        $this->assertStringContainsString('Exported 1 characters successfully', $output);

        $this->assertFileExists($tempFile);
        $content = file_get_contents($tempFile);
        $data = json_decode($content, true);
        $this->assertIsArray($data);
        $this->assertCount(1, $data);
        $this->assertEquals('Test Character', $data[0]['name']);
        $this->assertEquals(999, $data[0]['id']);

        unlink($tempFile);
    }

    public function testExecuteWithInvalidEntityType(): void
    {
        $kernel = self::bootKernel();
        $application = new Application($kernel);

        $command = $application->find('app:export');
        $commandTester = new CommandTester($command);

        $commandTester->execute([
            'entityType' => 'InvalidEntity',
            'outputFile' => '/tmp/test.json',
        ]);

        $this->assertEquals(1, $commandTester->getStatusCode());
        $output = $commandTester->getDisplay();
        $this->assertStringContainsString("Entity 'InvalidEntity' not found", $output);
    }

    public function testExecuteWithEmptyDatabase(): void
    {
        // Clear all characters
        $this->em->createQuery('DELETE FROM App\Entity\Character')->execute();

        $kernel = self::bootKernel();
        $application = new Application($kernel);

        $command = $application->find('app:export');
        $commandTester = new CommandTester($command);

        $tempFile = tempnam(sys_get_temp_dir(), 'test_empty');
        unlink($tempFile);
        $tempFile .= '.json';

        $commandTester->execute([
            'entityType' => 'Character',
            'outputFile' => $tempFile,
        ]);

        $commandTester->assertCommandIsSuccessful();
        $output = $commandTester->getDisplay();
        $this->assertStringContainsString('Exported 0 characters successfully', $output);

        $this->assertFileExists($tempFile);
        $content = file_get_contents($tempFile);
        $data = json_decode($content, true);
        $this->assertIsArray($data);
        $this->assertEmpty($data);

        unlink($tempFile);
    }

    public function testExecuteWithDefaultOutputFile(): void
    {
        // Backup existing file if it exists
        $defaultFile = 'data/characters.json';
        $backupContent = null;
        if (file_exists($defaultFile)) {
            $backupContent = file_get_contents($defaultFile);
        }

        // Create a test character
        $character = new Character();
        $character->setId(999);
        $character->setName('Test Character');
        $character->setStatus('Alive');
        $character->setSpecies('Human');
        $character->setType('');
        $character->setGender('Male');
        $character->setImage('https://example.com/image.jpg');
        $character->setUrl('https://example.com/character/1');
        $character->setCreated(new \DateTime());

        $this->em->persist($character);
        $this->em->flush();

        $kernel = self::bootKernel();
        $application = new Application($kernel);

        $command = $application->find('app:export');
        $commandTester = new CommandTester($command);

        $commandTester->execute([
            'entityType' => 'Character',
            // No outputFile provided
        ]);

        $commandTester->assertCommandIsSuccessful();
        $output = $commandTester->getDisplay();
        $this->assertStringContainsString('Exported 1 characters successfully', $output);

        $this->assertFileExists($defaultFile);
        $content = file_get_contents($defaultFile);
        $data = json_decode($content, true);
        $this->assertIsArray($data);
        $this->assertCount(1, $data);
        $this->assertEquals('Test Character', $data[0]['name']);

        // Restore or remove the file
        if (null !== $backupContent) {
            file_put_contents($defaultFile, $backupContent);
        } else {
            unlink($defaultFile);
        }
    }
}
