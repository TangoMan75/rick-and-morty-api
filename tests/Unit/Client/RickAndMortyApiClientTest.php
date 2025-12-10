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

namespace App\Tests\Unit\Client;

use App\Client\RickAndMortyApiClient;
use App\Entity\Character;
use App\Entity\Episode;
use App\Entity\Location;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\EntityRepository;
use PHPUnit\Framework\MockObject\Exception;
use PHPUnit\Framework\TestCase;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;
use Symfony\Contracts\HttpClient\HttpClientInterface;
use Symfony\Contracts\HttpClient\ResponseInterface;

class RickAndMortyApiClientTest extends TestCase
{
    private HttpClientInterface $httpClient;
    private EntityManagerInterface $em;
    private RickAndMortyApiClient $client;

    /**
     * @throws Exception
     */
    protected function setUp(): void
    {
        $this->httpClient = $this->createMock(HttpClientInterface::class);
        $this->em = $this->createMock(EntityManagerInterface::class);

        $this->client = new RickAndMortyApiClient($this->httpClient, $this->em);
    }

    /**
     * @throws RedirectionExceptionInterface
     * @throws ClientExceptionInterface
     * @throws TransportExceptionInterface
     * @throws Exception
     * @throws ServerExceptionInterface
     */
    public function testImportCharactersProcessesDataAndPersists(): void
    {
        $apiResponse = [
            'info' => [
                'count' => 2,
                'pages' => 1,
                'next'  => null,
                'prev'  => null,
            ],
            'results' => [
                [
                    'id'      => 1,
                    'name'    => 'Rick Sanchez',
                    'status'  => 'Alive',
                    'species' => 'Human',
                    'type'    => '',
                    'gender'  => 'Male',
                    'origin'  => [
                        'name' => 'Earth (C-137)',
                        'url'  => 'https://rickandmortyapi.com/api/location/1',
                    ],
                    'location' => [
                        'name' => 'Citadel of Ricks',
                        'url'  => 'https://rickandmortyapi.com/api/location/3',
                    ],
                    'image'   => 'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
                    'episode' => [
                        'https://rickandmortyapi.com/api/episode/1',
                    ],
                    'url'     => 'https://rickandmortyapi.com/api/character/1',
                    'created' => '2017-11-04T18:48:46.250Z',
                ],
            ],
        ];

        $locationData = [
            'id'        => 1,
            'name'      => 'Earth (C-137)',
            'type'      => 'Planet',
            'dimension' => 'Dimension C-137',
            'url'       => 'https://rickandmortyapi.com/api/location/1',
            'created'   => '2017-11-04T18:48:46.250Z',
        ];

        $episodeData = [
            'id'       => 1,
            'name'     => 'Pilot',
            'air_date' => 'December 2, 2013',
            'episode'  => 'S01E01',
            'url'      => 'https://rickandmortyapi.com/api/episode/1',
            'created'  => '2017-11-04T18:48:46.250Z',
        ];

        $characterResponse = $this->createMock(ResponseInterface::class);
        $characterResponse->method('getContent')->willReturn(json_encode($apiResponse));

        $locationResponse = $this->createMock(ResponseInterface::class);
        $locationResponse->method('getContent')->willReturn(json_encode($locationData));

        $episodeResponse = $this->createMock(ResponseInterface::class);
        $episodeResponse->method('getContent')->willReturn(json_encode($episodeData));

        $this->httpClient->expects($this->exactly(1))
            ->method('request')
            ->willReturn($characterResponse);

        $characterRepo = $this->createMock(EntityRepository::class);
        $characterRepo->method('findOneBy')->willReturn(null);

        $locationRepo = $this->createMock(EntityRepository::class);
        $locationRepo->method('findOneBy')->willReturn(null);

        $episodeRepo = $this->createMock(EntityRepository::class);
        $episodeRepo->method('findOneBy')->willReturn(null);

        $this->em->method('getRepository')
            ->willReturnMap([
                [Character::class, $characterRepo],
                [Location::class, $locationRepo],
                [Episode::class, $episodeRepo],
            ]);

        $this->em->expects($this->exactly(1))->method('persist');
        $this->em->expects($this->once())->method('flush');

        $this->client->importCharacters();
    }
}
