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

namespace App\Client;

use App\Entity\Character;
use App\Entity\Episode;
use App\Entity\Location;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;
use Symfony\Contracts\HttpClient\HttpClientInterface;

class RickAndMortyApiClient
{
    public const CHARACTERS_URL = 'https://rickandmortyapi.com/api/character';
    public const EPISODES_URL = 'https://rickandmortyapi.com/api/episode';
    public const LOCATIONS_URL = 'https://rickandmortyapi.com/api/location';

    private HttpClientInterface $httpClient;
    private EntityManagerInterface $em;

    public function __construct(HttpClientInterface $httpClient, EntityManagerInterface $em)
    {
        $this->httpClient = $httpClient;
        $this->em = $em;
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function getCharacterCount(): int
    {
        $response = $this->httpClient->request('GET', self::CHARACTERS_URL);
        $data = json_decode($response->getContent(), true);

        return $data['info']['count'];
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function importCharacters(?callable $progressCallback = null): void
    {
        $url = self::CHARACTERS_URL;

        while ($url) {
            $response = $this->httpClient->request('GET', $url);
            $data = json_decode($response->getContent(), true);

            foreach ($data['results'] as $item) {
                $this->processCharacter($item);
                if ($progressCallback) {
                    $progressCallback();
                }
            }

            $url = $data['info']['next'] ?? null;
            if ($url) {
                usleep(200000); // 200ms delay between requests
            }
        }

        $this->em->flush();
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function getEpisodeCount(): int
    {
        $response = $this->httpClient->request('GET', self::EPISODES_URL);
        $data = json_decode($response->getContent(), true);

        return $data['info']['count'];
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws ClientExceptionInterface
     * @throws \Exception
     */
    public function importEpisodes(?callable $progressCallback = null): void
    {
        $url = self::EPISODES_URL;

        while ($url) {
            $response = $this->httpClient->request('GET', $url);
            $data = json_decode($response->getContent(), true);

            foreach ($data['results'] as $item) {
                $this->processEpisode($item);
                if ($progressCallback) {
                    $progressCallback();
                }
            }

            $url = $data['info']['next'] ?? null;
            if ($url) {
                usleep(200000); // 200ms delay between requests
            }
        }

        $this->em->flush();
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function getLocationCount(): int
    {
        $response = $this->httpClient->request('GET', self::LOCATIONS_URL);
        $data = json_decode($response->getContent(), true);

        return $data['info']['count'];
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws ClientExceptionInterface
     * @throws \Exception
     */
    public function importLocations(?callable $progressCallback = null): void
    {
        $url = self::LOCATIONS_URL;

        while ($url) {
            $response = $this->httpClient->request('GET', $url);
            $data = json_decode($response->getContent(), true);

            foreach ($data['results'] as $item) {
                $this->processLocation($item);
                if ($progressCallback) {
                    $progressCallback();
                }
            }

            $url = $data['info']['next'] ?? null;
            if ($url) {
                usleep(200000); // 200ms delay between requests
            }
        }

        $this->em->flush();
    }

    /**
     * @throws RedirectionExceptionInterface
     * @throws ClientExceptionInterface
     * @throws ServerExceptionInterface
     * @throws \Exception
     */
    private function processCharacter(array $item): void
    {
        $character = $this->em->find(Character::class, $item['id']) ?? new Character();

        $character->setId($item['id']);
        $character->setName($item['name']);
        $character->setStatus($item['status']);
        $character->setSpecies($item['species']);
        $character->setType($item['type']);
        $character->setGender($item['gender']);
        $character->setImage($item['image']);
        $character->setUrl($item['url']);
        $character->setCreated(new \DateTime($item['created']));

        if (isset($item['origin'])) {
            $apiId = (int) basename($item['origin']['url']);
            $origin = $this->em->find(Location::class, $apiId);
            if ($origin) {
                $character->setOrigin($origin);
            }
        }

        if (isset($item['location'])) {
            $apiId = (int) basename($item['location']['url']);
            $location = $this->em->find(Location::class, $apiId);
            if ($location) {
                $character->setLocation($location);
            }
        }

        foreach ($item['episode'] as $episodeUrl) {
            $apiId = (int) basename($episodeUrl);
            $episode = $this->em->find(Episode::class, $apiId);
            if ($episode) {
                $character->addEpisode($episode);
            }
        }

        $this->em->persist($character);
    }

    /**
     * @throws \Exception
     */
    private function processEpisode(array $item): void
    {
        $episode = $this->em->find(Episode::class, $item['id']) ?? new Episode();

        $episode->setId($item['id']);
        $episode->setName($item['name']);
        $episode->setAirDate($item['air_date']);
        $episode->setEpisode($item['episode']);
        $episode->setUrl($item['url']);
        $episode->setCreated(new \DateTime($item['created']));

        foreach ($item['characters'] as $characterUrl) {
            $apiId = (int) basename($characterUrl);
            $character = $this->em->find(Character::class, $apiId);
            if ($character) {
                $episode->addCharacter($character);
            }
        }

        $this->em->persist($episode);
    }

    /**
     * @throws \Exception
     */
    private function processLocation(array $item): void
    {
        $location = $this->em->find(Location::class, $item['id']) ?? new Location();

        $location->setId($item['id']);
        $location->setName($item['name']);
        $location->setType($item['type']);
        $location->setDimension($item['dimension']);
        $location->setUrl($item['url']);
        $location->setCreated(new \DateTime($item['created']));

        $this->em->persist($location);
    }
}
