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

namespace App\Serializer\Normalizer;

use App\Entity\Character;
use App\Entity\Episode;
use App\Entity\Location;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\Exception\ORMException;
use Doctrine\ORM\OptimisticLockException;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\HttpFoundation\RequestStack;
use Symfony\Component\Serializer\Normalizer\DenormalizerInterface;
use Symfony\Component\Serializer\Normalizer\NormalizerInterface;

class CharacterNormalizer implements NormalizerInterface, DenormalizerInterface
{
    public function __construct(
        #[Autowire(service: 'serializer.normalizer.object')]
        private NormalizerInterface $normalizer,
        private EntityManagerInterface $em,
        private RequestStack $requestStack,
    ) {
    }

    public function normalize($data, ?string $format = null, array $context = []): array
    {
        $request = $this->requestStack->getCurrentRequest();
        $baseUrl = $request ? $request->getSchemeAndHttpHost() : 'http://127.0.0.1:8000';

        $context['circular_reference_handler'] = function ($data) {
            if ($data instanceof Episode) {
                return ['@id' => '/api/episodes/'.$data->getId()];
            } elseif ($data instanceof Location) {
                return ['@id' => '/api/locations/'.$data->getId()];
            }

            return null;
        };

        $normalized = $this->normalizer->normalize($data, $format, $context);
        $normalized['url'] = $baseUrl.'/api/characters/'.$data->getId();

        if (isset($normalized['location']) && is_array($normalized['location']) && isset($normalized['location']['url'])) {
            $normalized['location']['url'] = str_replace('https://rickandmortyapi.com/api/location/', $baseUrl.'/api/locations/', $normalized['location']['url']);
        }

        if (isset($normalized['episode'])) {
            $normalized['episode'] = array_map(function ($episode) use ($baseUrl) {
                if (is_string($episode)) {
                    return $baseUrl.$episode;
                }
                if (isset($episode['url'])) {
                    return str_replace('https://rickandmortyapi.com/api/episode/', $baseUrl.'/api/episodes/', $episode['url']);
                }
                if (isset($episode['@id'])) {
                    return $baseUrl.$episode['@id'];
                }

                return '';
            }, $normalized['episode']);
        }

        return $normalized;
    }

    public function supportsNormalization($data, ?string $format = null, array $context = []): bool
    {
        return $data instanceof Character;
    }

    /**
     * @throws OptimisticLockException
     * @throws ORMException
     * @throws \Exception
     */
    public function denormalize(mixed $data, string $type, ?string $format = null, array $context = []): mixed
    {
        $character = $this->em->find(Character::class, $data['id']) ?? new Character();

        $character->setId($data['id']);
        $character->setName($data['name']);
        $character->setStatus($data['status']);
        $character->setSpecies($data['species']);
        $character->setType($data['type']);
        $character->setGender($data['gender']);
        $character->setImage($data['image']);
        $character->setUrl($data['url']);
        $character->setCreated(new \DateTime($data['created']));

        if (isset($data['origin'])) {
            $id = (int) basename($data['origin']['url']);
            $origin = $this->em->find(Location::class, $id);
            if ($origin) {
                $character->setOrigin($origin);
            }
        }

        if (isset($data['location'])) {
            $id = (int) basename($data['location']['url']);
            $location = $this->em->find(Location::class, $id);
            if ($location) {
                $character->setLocation($location);
            }
        }

        if (isset($data['episode'])) {
            foreach ($data['episode'] as $episodeUrl) {
                $id = (int) basename($episodeUrl);
                $episode = $this->em->find(Episode::class, $id);
                if ($episode) {
                    $character->addEpisode($episode);
                }
            }
        }

        return $character;
    }

    public function supportsDenormalization(mixed $data, string $type, ?string $format = null, array $context = []): bool
    {
        return Character::class === $type && is_array($data);
    }

    public function getSupportedTypes(?string $format): array
    {
        return [Character::class => true];
    }
}
