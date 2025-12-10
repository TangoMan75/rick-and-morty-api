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

namespace App\Tests\Unit\Serializer\Normalizer;

use App\Entity\Character;
use App\Entity\Episode;
use App\Serializer\Normalizer\EpisodeNormalizer;
use Doctrine\ORM\EntityManagerInterface;
use PHPUnit\Framework\MockObject\Exception;
use PHPUnit\Framework\TestCase;
use Symfony\Component\HttpFoundation\RequestStack;
use Symfony\Component\Serializer\Normalizer\NormalizerInterface;

class EpisodeNormalizerTest extends TestCase
{
    private NormalizerInterface $normalizer;
    private EntityManagerInterface $em;
    private RequestStack $requestStack;
    private EpisodeNormalizer $episodeNormalizer;

    /**
     * @throws Exception
     */
    protected function setUp(): void
    {
        $this->normalizer = $this->createMock(NormalizerInterface::class);
        $this->em = $this->createMock(EntityManagerInterface::class);
        $this->requestStack = $this->createMock(RequestStack::class);
        $this->episodeNormalizer = new EpisodeNormalizer($this->normalizer, $this->em, $this->requestStack);
    }

    public function testNormalize(): void
    {
        $episode = new Episode();
        $episode->setId(1);
        $episode->setName('Pilot');

        $normalized = [
            'id'         => 1,
            'name'       => 'Pilot',
            'characters' => [
                ['@id'=>'/api/characters/1'],
                ['@id'=> '/api/characters/2'],
            ],
        ];
        $expected = [
            'id'         => 1,
            'name'       => 'Pilot',
            'characters' => [
                'http://127.0.0.1:8000/api/characters/1',
                'http://127.0.0.1:8000/api/characters/2',
            ],
            'url' => 'http://127.0.0.1:8000/api/episodes/1',
        ];

        $this->normalizer->expects($this->once())
            ->method('normalize')
            ->with($episode, null, $this->callback(function ($context) {
                return isset($context['circular_reference_handler']);
            }))
            ->willReturn($normalized);

        $result = $this->episodeNormalizer->normalize($episode);

        $this->assertEquals($expected, $result);
    }

    public function testSupportsNormalization(): void
    {
        $episode = new Episode();
        $this->assertTrue($this->episodeNormalizer->supportsNormalization($episode));
        $this->assertFalse($this->episodeNormalizer->supportsNormalization('string'));
    }

    public function testDenormalize(): void
    {
        $data = [
            'id'       => 1,
            'name'     => 'Pilot',
            'air_date' => 'December 2, 2013',
            'episode'  => 'S01E01',
            'url'      => 'https://rickandmortyapi.com/api/episode/1',
            'created'  => '2017-11-04T18:48:46.250Z',
        ];

        $this->em->method('find')->willReturn(null);

        $result = $this->episodeNormalizer->denormalize($data, Episode::class);

        $this->assertInstanceOf(Episode::class, $result);
        $this->assertEquals($data['id'], $result->getId());
        $this->assertEquals($data['name'], $result->getName());
        $this->assertEquals($data['air_date'], $result->getAirDate());
        $this->assertEquals($data['episode'], $result->getEpisode());
        $this->assertEquals($data['url'], $result->getUrl());
        $this->assertInstanceOf(\DateTime::class, $result->getCreated());
    }

    public function testSupportsDenormalization(): void
    {
        $data = ['id' => 1];
        $this->assertTrue($this->episodeNormalizer->supportsDenormalization($data, Episode::class));
        $this->assertFalse($this->episodeNormalizer->supportsDenormalization($data, Character::class));
        $this->assertFalse($this->episodeNormalizer->supportsDenormalization('string', Episode::class));
    }

    public function testGetSupportedTypes(): void
    {
        $expected = [Episode::class => true];
        $this->assertEquals($expected, $this->episodeNormalizer->getSupportedTypes(null));
    }
}
