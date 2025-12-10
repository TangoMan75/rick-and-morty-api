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

use App\Entity\Location;
use App\Serializer\Normalizer\LocationNormalizer;
use Doctrine\ORM\EntityManagerInterface;
use PHPUnit\Framework\MockObject\Exception;
use PHPUnit\Framework\TestCase;
use Symfony\Component\HttpFoundation\RequestStack;
use Symfony\Component\Serializer\Normalizer\NormalizerInterface;

class LocationNormalizerTest extends TestCase
{
    private NormalizerInterface $normalizer;
    private EntityManagerInterface $em;
    private RequestStack $requestStack;
    private LocationNormalizer $locationNormalizer;

    /**
     * @throws Exception
     */
    protected function setUp(): void
    {
        $this->normalizer = $this->createMock(NormalizerInterface::class);
        $this->em = $this->createMock(EntityManagerInterface::class);
        $this->requestStack = $this->createMock(RequestStack::class);
        $this->locationNormalizer = new LocationNormalizer($this->normalizer, $this->em, $this->requestStack);
    }

    public function testNormalize(): void
    {
        $location = new Location();
        $location->setId(1);
        $location->setName('Earth (C-137)');

        $normalizedData = [
            'id'        => 1,
            'name'      => 'Earth (C-137)',
            'residents' => [
                ['@id' => '/api/characters/1'],
                ['@id' => '/api/characters/2'],
            ],
        ];

        $expected = [
            'id'        => 1,
            'name'      => 'Earth (C-137)',
            'residents' => [
                'http://127.0.0.1:8000/api/characters/1',
                'http://127.0.0.1:8000/api/characters/2',
            ],
            'url' => 'http://127.0.0.1:8000/api/locations/1',
        ];

        $this->normalizer->expects($this->once())
            ->method('normalize')
            ->with($location, null, $this->callback(function ($context) {
                return isset($context['circular_reference_handler']);
            }))
            ->willReturn($normalizedData);

        $result = $this->locationNormalizer->normalize($location);

        $this->assertEquals($expected, $result);
    }

    public function testSupportsNormalization(): void
    {
        $location = new Location();
        $this->assertTrue($this->locationNormalizer->supportsNormalization($location));
        $this->assertFalse($this->locationNormalizer->supportsNormalization('string'));
    }

    public function testDenormalize(): void
    {
        $data = [
            'id'        => 1,
            'name'      => 'Earth (C-137)',
            'type'      => 'Planet',
            'dimension' => 'Dimension C-137',
            'url'       => 'https://rickandmortyapi.com/api/location/1',
            'created'   => '2017-11-04T18:48:46.250Z',
        ];

        $this->em->method('find')->willReturn(null);

        $result = $this->locationNormalizer->denormalize($data, Location::class);

        $this->assertInstanceOf(Location::class, $result);
        $this->assertEquals($data['id'], $result->getId());
        $this->assertEquals($data['name'], $result->getName());
        $this->assertEquals($data['type'], $result->getType());
        $this->assertEquals($data['dimension'], $result->getDimension());
        $this->assertEquals($data['url'], $result->getUrl());
        $this->assertInstanceOf(\DateTime::class, $result->getCreated());
    }

    public function testSupportsDenormalization(): void
    {
        $data = ['id' => 1];
        $this->assertTrue($this->locationNormalizer->supportsDenormalization($data, Location::class));
        $this->assertFalse($this->locationNormalizer->supportsDenormalization($data, \App\Entity\Character::class));
        $this->assertFalse($this->locationNormalizer->supportsDenormalization('string', Location::class));
    }

    public function testGetSupportedTypes(): void
    {
        $expected = [Location::class => true];
        $this->assertEquals($expected, $this->locationNormalizer->getSupportedTypes(null));
    }
}
