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
use App\Entity\Location;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\Exception\ORMException;
use Doctrine\ORM\OptimisticLockException;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\HttpFoundation\RequestStack;
use Symfony\Component\Serializer\Normalizer\DenormalizerInterface;
use Symfony\Component\Serializer\Normalizer\NormalizerInterface;

class LocationNormalizer implements NormalizerInterface, DenormalizerInterface
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
            if ($data instanceof Character) {
                return ['@id' => '/api/characters/'.$data->getId()];
            }

            return null;
        };

        $normalized = $this->normalizer->normalize($data, $format, $context);
        $normalized['url'] = $baseUrl.'/api/locations/'.$data->getId();

        if (isset($normalized['residents'])) {
            $normalized['residents'] = array_map(function ($resident) use ($baseUrl) {
                if (is_string($resident)) {
                    return $baseUrl.$resident;
                }
                if (isset($resident['url'])) {
                    return str_replace('https://rickandmortyapi.com/api/character/', $baseUrl.'/api/characters/', $resident['url']);
                }
                if (isset($resident['@id'])) {
                    return $baseUrl.$resident['@id'];
                }

                return '';
            }, $normalized['residents']);
        }

        return $normalized;
    }

    public function supportsNormalization($data, ?string $format = null, array $context = []): bool
    {
        return $data instanceof Location;
    }

    /**
     * @throws OptimisticLockException
     * @throws ORMException
     * @throws \Exception
     */
    public function denormalize(mixed $data, string $type, ?string $format = null, array $context = []): mixed
    {
        $location = $this->em->find(Location::class, $data['id']) ?? new Location();

        $location->setId($data['id']);
        $location->setName($data['name']);
        $location->setType($data['type']);
        $location->setDimension($data['dimension']);
        $location->setUrl($data['url']);
        $location->setCreated(new \DateTime($data['created']));

        if (isset($data['residents'])) {
            foreach ($data['residents'] as $characterUrl) {
                $id = (int) basename($characterUrl);
                $character = $this->em->find(Character::class, $id);
                if ($character) {
                    $location->addResident($character);
                }
            }
        }

        return $location;
    }

    public function supportsDenormalization(mixed $data, string $type, ?string $format = null, array $context = []): bool
    {
        return Location::class === $type && is_array($data);
    }

    public function getSupportedTypes(?string $format): array
    {
        return [Location::class => true];
    }
}
