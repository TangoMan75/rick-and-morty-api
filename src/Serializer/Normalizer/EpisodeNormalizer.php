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
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\Exception\ORMException;
use Doctrine\ORM\OptimisticLockException;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\HttpFoundation\RequestStack;
use Symfony\Component\Serializer\Normalizer\DenormalizerInterface;
use Symfony\Component\Serializer\Normalizer\NormalizerInterface;

class EpisodeNormalizer implements NormalizerInterface, DenormalizerInterface
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
        $normalized['url'] = $baseUrl.'/api/episodes/'.$data->getId();

        // Customize characters field to be array of URLs
        if (isset($normalized['characters'])) {
            $normalized['characters'] = array_map(function ($character) use ($baseUrl) {
                if (is_string($character)) {
                    return $baseUrl.$character;
                }
                if (isset($character['url'])) {
                    return str_replace('https://rickandmortyapi.com/api/character/', $baseUrl.'/api/characters/', $character['url']);
                }
                if (isset($character['@id'])) {
                    return $baseUrl.$character['@id'];
                }

                return '';
            }, $normalized['characters']);
        }

        return $normalized;
    }

    /**
     * @throws OptimisticLockException
     * @throws ORMException
     * @throws \Exception
     */
    public function denormalize(mixed $data, string $type, ?string $format = null, array $context = []): mixed
    {
        $episode = $this->em->find(Episode::class, $data['id']) ?? new Episode();

        $episode->setId($data['id']);
        $episode->setName($data['name']);
        $episode->setAirDate($data['air_date']);
        $episode->setEpisode($data['episode']);
        $episode->setUrl($data['url']);
        $episode->setCreated(new \DateTime($data['created']));

        if (isset($data['characters'])) {
            foreach ($data['characters'] as $characterUrl) {
                $id = (int) basename($characterUrl);
                $character = $this->em->find(Character::class, $id);
                if ($character) {
                    $episode->addCharacter($character);
                }
            }
        }

        return $episode;
    }

    public function supportsDenormalization(mixed $data, string $type, ?string $format = null, array $context = []): bool
    {
        return Episode::class === $type && is_array($data);
    }

    public function supportsNormalization($data, ?string $format = null, array $context = []): bool
    {
        return $data instanceof Episode;
    }

    public function getSupportedTypes(?string $format): array
    {
        return [Episode::class => true];
    }
}
