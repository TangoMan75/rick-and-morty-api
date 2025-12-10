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

namespace App\Command;

use App\Entity\Character;
use App\Entity\Episode;
use App\Entity\Location;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;
use Symfony\Component\Serializer\Exception\ExceptionInterface;
use Symfony\Component\Serializer\Normalizer\DenormalizerInterface;

#[AsCommand(
    name: 'app:import',
    description: 'Import data from JSON file into the database.',
)]
class ImportCommand extends Command
{
    private EntityManagerInterface $em;
    private DenormalizerInterface $denormalizer;

    public function __construct(EntityManagerInterface $em, DenormalizerInterface $denormalizer)
    {
        parent::__construct();
        $this->em = $em;
        $this->denormalizer = $denormalizer;
    }

    protected function configure(): void
    {
        $this->addArgument('file', InputArgument::REQUIRED, 'The path to the JSON file to import.');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $filePath = $input->getArgument('file');

        if (!file_exists($filePath)) {
            $io->error(sprintf('File not found: %s', basename($filePath)));

            return Command::FAILURE;
        }

        $content = file_get_contents($filePath);
        $data = json_decode($content, true);

        if (JSON_ERROR_NONE !== json_last_error()) {
            $io->error('Invalid JSON format');

            return Command::FAILURE;
        }

        $fileName = basename($filePath);
        $entityType = $this->getEntityType($fileName);

        if (!$entityType) {
            $io->error(sprintf('Cannot determine entity type from filename: %s', $fileName));

            return Command::FAILURE;
        }

        $this->importData($io, $data, $entityType);

        return Command::SUCCESS;
    }

    private function getEntityType(string $fileName): ?string
    {
        return match ($fileName) {
            'characters.json' => Character::class,
            'episodes.json'   => Episode::class,
            'locations.json'  => Location::class,
            default           => null,
        };
    }

    private function importData(SymfonyStyle $io, array $data, string $entityType): void
    {
        $importedCount = 0;
        $failedCount = 0;

        $progressBar = $io->createProgressBar(count($data));
        $io->writeln(sprintf('Starting import of %d %s...', count($data), lcfirst($this->getShortClassName($entityType)).'s'));
        $progressBar->start();

        foreach ($data as $item) {
            try {
                $this->processItem($item, $entityType);
                ++$importedCount;
                $io->writeln(sprintf('Imported %s with id %s', lcfirst($this->getShortClassName($entityType)), $item['id'] ?? 'N/A'), OutputInterface::VERBOSITY_VERBOSE);
            } catch (\Exception $e) {
                ++$failedCount;
                $io->warning(sprintf('Failed to import item with id %s: %s', $item['id'] ?? 'N/A', $e->getMessage()));
            }
            $progressBar->advance();
        }

        $progressBar->finish();
        $io->newLine(2);

        $this->em->flush();

        if ($failedCount > 0) {
            $io->warning(sprintf('Imported %d items, %d failed', $importedCount, $failedCount));
        } else {
            $io->success(sprintf('Imported %d %s successfully', $importedCount, lcfirst($this->getShortClassName($entityType)).'s'));
        }
    }

    /**
     * @throws ExceptionInterface
     */
    private function processItem(array $item, string $entityType): void
    {
        $entity = $this->denormalizer->denormalize($item, $entityType);
        $this->em->persist($entity);
    }

    private function getShortClassName(string $fqcn): string
    {
        $parts = explode('\\', $fqcn);

        return end($parts);
    }
}
