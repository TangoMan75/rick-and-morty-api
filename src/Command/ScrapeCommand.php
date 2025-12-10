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

use App\Client\RickAndMortyApiClient;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;

#[AsCommand(
    name: 'app:scrape',
    description: 'Scrape data from Rick and Morty API into the database.',
)]
class ScrapeCommand extends Command
{
    private RickAndMortyApiClient $client;

    public function __construct(RickAndMortyApiClient $client)
    {
        parent::__construct();
        $this->client = $client;
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);

        try {
            $locationCount = $this->client->getLocationCount();
            $episodeCount = $this->client->getEpisodeCount();
            $characterCount = $this->client->getCharacterCount();

            $io->writeln('Starting data import from Rick and Morty API...');

            $progressBar = $io->createProgressBar($locationCount);
            $progressBar->setFormat('verbose');
            $io->writeln('Importing locations...');
            $this->client->importLocations(function () use ($progressBar) { $progressBar->advance(); });
            $progressBar->finish();
            $io->writeln('');

            $progressBar = $io->createProgressBar($episodeCount);
            $progressBar->setFormat('verbose');
            $io->writeln('Importing episodes...');
            $this->client->importEpisodes(function () use ($progressBar) { $progressBar->advance(); });
            $progressBar->finish();
            $io->writeln('');

            $progressBar = $io->createProgressBar($characterCount);
            $progressBar->setFormat('verbose');
            $io->writeln('Importing characters...');
            $this->client->importCharacters(function () use ($progressBar) { $progressBar->advance(); });
            $progressBar->finish();
            $io->writeln('');

            $io->success('Data imported successfully');
        } catch (TransportExceptionInterface|ServerExceptionInterface|RedirectionExceptionInterface|ClientExceptionInterface) {
            $io->error('Invalid JSON response');

            return Command::FAILURE;
        } catch (\Exception) {
            $io->error('Database connection failed');

            return Command::FAILURE;
        }

        return Command::SUCCESS;
    }
}
