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
use Symfony\Bridge\Doctrine\Validator\Constraints\UniqueEntity;
use Symfony\Component\Serializer\Annotation\Groups;
use Symfony\Component\Validator\Constraints as Assert;

/**
 * A person (alive, dead, undead, or fictional).
 *
 * @see https://schema.org/Person
 *
 * @author "Matthias Morin" <mat@tangoman.io>
 */
#[ORM\Entity]
#[ORM\Table(name: '`character`')]
#[ApiResource(
    shortName: 'Character',
    description: 'A character entity from the Rick and Morty universe.',
    types: ['https://schema.org/Person'],
    operations: [new Get(), new GetCollection()],
    normalizationContext: ['groups' => ['character:read']]
)]
#[UniqueEntity(fields: ['image', 'url'])]
class Character
{
    #[ApiProperty(description: 'Unique Rick and Morty API identifier for the character.')]
    #[Groups('character:read')]
    #[ORM\Column(type: 'integer')]
    #[ORM\Id]
    private int $id = 0;

    /**
     * The name of the item.
     *
     * @see https://schema.org/name
     */
    #[ApiProperty(description: 'The name of the character.', types: ['https://schema.org/name'])]
    #[Assert\NotNull]
    #[Assert\Type('string')]
    #[Groups('character:read')]
    #[ORM\Column(type: 'text')]
    private string $name;

    /**
     * @see _:status
     */
    #[ApiProperty(description: 'The status of the character (\'Alive\', \'Dead\' or \'unknown\').')]
    #[Assert\Type(type: 'string')]
    #[Groups('character:read')]
    #[ORM\Column(type: 'text')]
    private string $status;

    /**
     * @see _:species
     */
    #[ApiProperty(description: 'The species of the character.')]
    #[Assert\Type(type: 'string')]
    #[Groups('character:read')]
    #[ORM\Column(type: 'text')]
    private string $species;

    /**
     * @see _:type
     */
    #[ApiProperty(description: 'The type or subspecies of the character.')]
    #[Assert\Type(type: 'string')]
    #[Groups('character:read')]
    #[ORM\Column(type: 'text')]
    private string $type;

    /**
     * Gender of something, typically a \[\[Person\]\], but possibly also fictional characters, animals, etc. While https://schema.org/Male and https://schema.org/Female may be used, text strings are also acceptable for people who are not a binary gender. The \[\[gender\]\] property can also be used in an extended sense to cover e.g. the gender of sports teams. As with the gender of individuals, we do not try to enumerate all possibilities. A mixed-gender \[\[SportsTeam\]\] can be indicated with a text value of "Mixed".
     *
     * @see https://schema.org/gender
     */
    #[ApiProperty(
        description: 'The gender of the character (\'Female\', \'Male\', \'Genderless\' or \'unknown\').',
        types: ['https://schema.org/gender'],
    )]
    #[Assert\Type('string')]
    #[Groups('character:read')]
    #[ORM\Column(type: 'text')]
    private ?string $gender = null;

    /**
     * @see _:origin
     */
    #[ApiProperty(description: 'Name and link to the character\'s origin location.')]
    #[Groups('character:read')]
    #[ORM\JoinColumn(nullable: true)]
    #[ORM\ManyToOne(targetEntity: 'App\Entity\Location')]
    private ?Location $origin = null;

    /**
     * @see _:location
     */
    #[ApiProperty(description: 'Name and link to the character\'s last known location endpoint.')]
    #[Groups('character:read')]
    #[ORM\JoinColumn(nullable: true)]
    #[ORM\ManyToOne(targetEntity: 'App\Entity\Location')]
    private ?Location $location;

    /**
     * An image of the item. This can be a \[\[URL\]\] or a fully described \[\[ImageObject\]\].
     *
     * @see https://schema.org/image
     */
    #[ApiProperty(
        description: 'Link to the character\'s image. All images are 300x300px and most are medium shots or portraits since they are intended to be used as avatars.',
        types: ['https://schema.org/image'],
    )]
    #[Assert\Url]
    #[Groups('character:read')]
    #[ORM\Column(type: 'text', unique: true)]
    private string $image;

    /**
     * @var Collection<Episode>
     *
     * @see _:episode
     */
    #[ApiProperty(description: 'List of episodes in which the character appeared.')]
    #[Groups('character:read')]
    #[ORM\ManyToMany(targetEntity: 'App\Entity\Episode', inversedBy: 'characters')]
    private Collection $episode;

    /**
     * URL of the item.
     *
     * @see https://schema.org/url
     */
    #[ApiProperty(description: 'Link to the character\'s own URL endpoint.', types: ['https://schema.org/url'])]
    #[Assert\Url]
    #[Groups('character:read')]
    #[ORM\Column(type: 'text', unique: true)]
    private string $url;

    /**
     * @see _:created
     */
    #[ApiProperty(description: 'The timestamp when the resource was created as a ISO 8601 timestamp (e.g., yyyy-MM-ddTHH:mm:ss.SSSZ).')]
    #[Groups('character:read')]
    #[ORM\Column(type: 'datetime')]
    private ?\DateTimeInterface $created = null;

    public function __construct()
    {
        $this->episode = new ArrayCollection();
        $this->location = null;
        $this->origin = null;
        $this->created = null;
        $this->gender = null;
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

    public function setStatus($status): void
    {
        $this->status = $status;
    }

    public function getStatus(): string
    {
        return $this->status;
    }

    public function setSpecies($species): void
    {
        $this->species = $species;
    }

    public function getSpecies(): string
    {
        return $this->species;
    }

    public function setType($type): void
    {
        $this->type = $type;
    }

    public function getType(): string
    {
        return $this->type;
    }

    public function setGender(?string $gender): void
    {
        $this->gender = $gender;
    }

    public function getGender(): ?string
    {
        return $this->gender;
    }

    public function setOrigin(?Location $origin): void
    {
        $this->origin = $origin;
    }

    public function getOrigin(): ?Location
    {
        return $this->origin;
    }

    public function setLocation(?Location $location): void
    {
        $oldLocation = $this->location;
        $this->location = $location;
        if (null !== $oldLocation && $oldLocation !== $location) {
            $oldLocation->removeResident($this);
        }
        if (null !== $location && !$location->getResidents()->contains($this)) {
            $location->addResident($this);
        }
    }

    public function getLocation(): ?Location
    {
        return $this->location;
    }

    public function setImage(string $image): void
    {
        $this->image = $image;
    }

    public function getImage(): string
    {
        return $this->image;
    }

    public function addEpisode(Episode $episode): void
    {
        if (!$this->episode->contains($episode)) {
            $this->episode[] = $episode;
            $episode->addCharacter($this);
        }
    }

    public function removeEpisode(Episode $episode): void
    {
        if ($this->episode->contains($episode)) {
            $this->episode->removeElement($episode);
            $episode->removeCharacter($this);
        }
    }

    /**
     * @return Collection<Episode>
     */
    public function getEpisode(): Collection
    {
        return $this->episode;
    }

    public function setUrl(string $url): void
    {
        $this->url = $url;
    }

    public function getUrl(): string
    {
        return $this->url;
    }

    public function setCreated(?\DateTimeInterface $created): void
    {
        $this->created = $created;
    }

    public function getCreated(): ?\DateTimeInterface
    {
        return $this->created;
    }
}
