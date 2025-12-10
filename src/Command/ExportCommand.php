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
use Symfony\Component\Serializer\Normalizer\NormalizerInterface;

#[AsCommand(
    name: 'app:export',
    description: 'Export data from database to JSON file.',
)]
class ExportCommand extends Command
{
    private EntityManagerInterface $em;
    private NormalizerInterface $serializer;

    public function __construct(
        EntityManagerInterface $em,
        NormalizerInterface $serializer,
    ) {
        parent::__construct();
        $this->em = $em;
        $this->serializer = $serializer;
    }

    protected function configure(): void
    {
        $this->addArgument('entityType', InputArgument::REQUIRED, 'The entity type to export (Character, Episode, Location).')
             ->addArgument('outputFile', InputArgument::OPTIONAL, 'The path to the output JSON file. Defaults to data/{entityType}.json');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $entityType = $input->getArgument('entityType');
        $outputFile = $input->getArgument('outputFile');

        if (!$outputFile) {
            $outputFile = 'data/'.strtolower($entityType).'s.json';
        }

        $entityClass = $this->getEntityClass($entityType);

        if (!$entityClass) {
            $io->error(sprintf("Entity '%s' not found. Supported types: Character, Episode, Location", $entityType));

            return Command::FAILURE;
        }

        $repository = $this->em->getRepository($entityClass);
        $entities = $repository->findAll();

        $data = [];
        foreach ($entities as $entity) {
            $data[] = $this->entityToArray($entity);
        }

        $json = json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);

        if (false === $json) {
            $io->error('Failed to encode data to JSON');

            return Command::FAILURE;
        }

        $dir = dirname($outputFile);
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }

        if (false === file_put_contents($outputFile, $json)) {
            $io->error(sprintf('Failed to write to file: %s', $outputFile));

            return Command::FAILURE;
        }

        $count = count($entities);
        $entityName = lcfirst($entityType).'s';
        $io->success(sprintf('Exported %d %s successfully', $count, $entityName));

        return Command::SUCCESS;
    }

    private function getEntityClass(string $entityType): ?string
    {
        return match ($entityType) {
            'Character' => Character::class,
            'Episode'   => Episode::class,
            'Location'  => Location::class,
            default     => null,
        };
    }

    private function entityToArray(object $entity): array
    {
        return match (true) {
            $entity instanceof Character => $this->serializer->normalize($entity, 'json', ['groups' => ['character:read']]),
            $entity instanceof Episode   => $this->serializer->normalize($entity, 'json', ['groups' => ['episode:read']]),
            $entity instanceof Location  => $this->serializer->normalize($entity, 'json', ['groups' => ['location:read']]),
            default                      => [],
        };
    }
}
