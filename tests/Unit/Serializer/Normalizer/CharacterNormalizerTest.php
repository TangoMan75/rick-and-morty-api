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
use App\Serializer\Normalizer\CharacterNormalizer;
use Doctrine\ORM\EntityManagerInterface;
use PHPUnit\Framework\MockObject\Exception;
use PHPUnit\Framework\TestCase;
use Symfony\Component\HttpFoundation\RequestStack;
use Symfony\Component\Serializer\Normalizer\NormalizerInterface;

class CharacterNormalizerTest extends TestCase
{
    private NormalizerInterface $normalizer;
    private EntityManagerInterface $em;
    private RequestStack $requestStack;
    private CharacterNormalizer $characterNormalizer;

    /**
     * @throws Exception
     */
    protected function setUp(): void
    {
        $this->normalizer = $this->createMock(NormalizerInterface::class);
        $this->em = $this->createMock(EntityManagerInterface::class);
        $this->requestStack = $this->createMock(RequestStack::class);
        $this->characterNormalizer = new CharacterNormalizer($this->normalizer, $this->em, $this->requestStack);
    }

    public function testNormalize(): void
    {
        $character = new Character();
        $character->setId(1);
        $character->setName('Rick Sanchez');

        $normalizedData = [
            'id'      => 1,
            'name'    => 'Rick Sanchez',
            'episode' => [
                ['@id' => '/api/episodes/1'],
                ['@id' => '/api/episodes/2'],
            ],
        ];

        $expected = [
            'id'      => 1,
            'name'    => 'Rick Sanchez',
            'episode' => [
                'http://127.0.0.1:8000/api/episodes/1',
                'http://127.0.0.1:8000/api/episodes/2',
            ],
            'url' => 'http://127.0.0.1:8000/api/characters/1',
        ];

        $this->normalizer->expects($this->once())
            ->method('normalize')
            ->with($character, null, $this->callback(function ($context) {
                return isset($context['circular_reference_handler']);
            }))
            ->willReturn($normalizedData);

        $result = $this->characterNormalizer->normalize($character);

        $this->assertEquals($expected, $result);
    }

    public function testSupportsNormalization(): void
    {
        $character = new Character();
        $this->assertTrue($this->characterNormalizer->supportsNormalization($character));
        $this->assertFalse($this->characterNormalizer->supportsNormalization('string'));
    }

    public function testDenormalize(): void
    {
        $data = [
            'id'      => 1,
            'name'    => 'Rick Sanchez',
            'status'  => 'Alive',
            'species' => 'Human',
            'type'    => '',
            'gender'  => 'Male',
            'image'   => 'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
            'url'     => 'https://rickandmortyapi.com/api/character/1',
            'created' => '2017-11-04T18:48:46.000Z',
        ];

        $this->em->method('find')->willReturn(null);

        $result = $this->characterNormalizer->denormalize($data, Character::class);

        $this->assertInstanceOf(Character::class, $result);
        $this->assertEquals($data['id'], $result->getId());
        $this->assertEquals($data['name'], $result->getName());
        $this->assertEquals($data['status'], $result->getStatus());
        $this->assertEquals($data['species'], $result->getSpecies());
        $this->assertEquals($data['type'], $result->getType());
        $this->assertEquals($data['gender'], $result->getGender());
        $this->assertEquals($data['image'], $result->getImage());
        $this->assertEquals($data['url'], $result->getUrl());
        $this->assertInstanceOf(\DateTime::class, $result->getCreated());
    }

    public function testSupportsDenormalization(): void
    {
        $data = ['id' => 1];
        $this->assertTrue($this->characterNormalizer->supportsDenormalization($data, Character::class));
        $this->assertFalse($this->characterNormalizer->supportsDenormalization($data, \App\Entity\Episode::class));
        $this->assertFalse($this->characterNormalizer->supportsDenormalization('string', Character::class));
    }

    public function testGetSupportedTypes(): void
    {
        $expected = [Character::class => true];
        $this->assertEquals($expected, $this->characterNormalizer->getSupportedTypes(null));
    }
}
