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

namespace App\Entity;

use ApiPlatform\Metadata\ApiProperty;
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Annotation\Groups;
use Symfony\Component\Validator\Constraints as Assert;

/**
 * The most generic type of item.
 *
 * @see https://schema.org/Thing
 *
 * @author "Matthias Morin" <mat@tangoman.io>
 */
#[ORM\Entity]
#[ApiResource(
    shortName: 'Location',
    description: 'Define Location as an API Resource',
    types: ['https://schema.org/Thing'],
    operations: [new Get(), new GetCollection()],
    normalizationContext: ['groups' => ['location:read'], 'max_depth' => 2]
)]
class Location
{
    #[ApiProperty(description: 'Unique Rick and Morty API identifier for the location.')]
    #[Groups(['location:read'])]
    #[ORM\Column(type: 'integer')]
    #[ORM\Id]
    private int $id = 0;

    /**
     * The name of the item.
     *
     * @see https://schema.org/name
     */
    #[ApiProperty(description: 'The name of the location.', types: ['https://schema.org/name'])]
    #[Assert\NotNull]
    #[Assert\Type('string')]
    #[Groups(['location:read', 'character:read'])]
    #[ORM\Column(type: 'text')]
    private string $name;

    /**
     * @see _:type
     */
    #[ApiProperty(description: 'The type of the location (e.g., Planet, Cluster).')]
    #[Assert\Type(type: 'string')]
    #[Groups(['location:read'])]
    #[ORM\Column(type: 'text', nullable: true)]
    private ?string $type;

    /**
     * @see _:dimension
     */
    #[ApiProperty(description: 'The dimension in which the location is located.')]
    #[Assert\Type(type: 'string')]
    #[Groups(['location:read'])]
    #[ORM\Column(type: 'text', nullable: true)]
    private ?string $dimension;

    /**
     * @var Collection<Character>
     *
     * @see _:residents
     */
    #[ApiProperty(description: 'List of character who have been last seen in the location.')]
    #[Assert\NotNull]
    #[Groups(['location:read'])]
    #[ORM\InverseJoinColumn(unique: true, nullable: false)]
    #[ORM\ManyToMany(targetEntity: 'App\Entity\Character')]
    private Collection $residents;

    /**
     * URL of the item.
     *
     * @see https://schema.org/url
     */
    #[ApiProperty(description: 'Link to the location\'s own endpoint.', types: ['https://schema.org/url'])]
    #[Assert\Url]
    #[Groups(['location:read', 'character:read'])]
    #[ORM\Column(type: 'text', nullable: true)]
    private string $url;

    /**
     * @see _:created
     */
    #[ApiProperty(description: 'The timestamp when the resource was created as a ISO 8601 timestamp (e.g., yyyy-MM-ddTHH:mm:ss.SSSZ).')]
    #[Groups('location:read')]
    #[ORM\Column(type: 'datetime', nullable: true)]
    private ?\DateTimeInterface $created = null;

    public function __construct()
    {
        $this->residents = new ArrayCollection();
    }

    public function getId(): int
    {
        return $this->id;
    }

    public function setId(int $id): void
    {
        $this->id = $id;
    }

    public function setName(string $name): void
    {
        $this->name = $name;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function setType(?string $type): void
    {
        $this->type = $type;
    }

    public function getType(): ?string
    {
        return $this->type;
    }

    public function setDimension(?string $dimension): void
    {
        $this->dimension = $dimension;
    }

    public function getDimension(): ?string
    {
        return $this->dimension;
    }

    public function addResident(Character $resident): void
    {
        if (!$this->residents->contains($resident)) {
            $this->residents[] = $resident;
            $resident->setLocation($this);
        }
    }

    public function removeResident(Character $resident): void
    {
        if ($this->residents->contains($resident)) {
            $this->residents->removeElement($resident);
            $resident->setLocation(null);
        }
    }

    /**
     * @return Collection<Character>
     */
    public function getResidents(): Collection
    {
        return $this->residents;
    }

    public function setUrl(string $url): void
    {
        $this->url = $url;
    }

    public function getUrl(): string
    {
        return $this->url;
    }

    public function setCreated($created): void
    {
        $this->created = $created;
    }

    public function getCreated(): ?\DateTimeInterface
    {
        return $this->created;
    }
}
