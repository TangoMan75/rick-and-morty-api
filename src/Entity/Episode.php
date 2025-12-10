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
 * A media episode (e.g. TV, radio, video game) which can be part of a series or season.
 *
 * @see https://schema.org/Episode
 *
 * @author "Matthias Morin" <mat@tangoman.io>
 */
#[ORM\Entity]
#[ApiResource(
    description: 'Define Episode as an API Resource',
    types: ['https://schema.org/Episode'],
    operations: [new Get(), new GetCollection()],
    normalizationContext: ['groups' => ['episode:read']]
)]
class Episode
{
    #[ApiProperty(description: 'Unique Rick and Morty API identifier for the episode.')]
    #[Groups(['episode:read'])]
    #[ORM\Column(type: 'integer')]
    #[ORM\Id]
    private int $id = 0;

    /**
     * The name of the item.
     *
     * @see https://schema.org/name
     */
    #[ApiProperty(description: 'The name of the episode.', types: ['https://schema.org/name'])]
    #[Assert\NotNull]
    #[Assert\Type('string')]
    #[Groups(['episode:read'])]
    #[ORM\Column(type: 'text', nullable: true)]
    private string $name;

    /**
     * @see _:airDate
     */
    #[ApiProperty(description: 'The air date of the episode as a Long Date Format (e.g., MMMM d, yyyy)')]
    #[Assert\Type(type: 'string')]
    #[Groups(['episode:read'])]
    #[ORM\Column(type: 'text', nullable: true)]
    private string $airDate;

    /**
     * @see _:episode
     */
    #[ApiProperty(description: 'The code of the episode. (e.g., "S01E01").')]
    #[Assert\Type(type: 'string')]
    #[Groups(['episode:read'])]
    #[ORM\Column(type: 'text', nullable: true)]
    private string $episode;

    /**
     * @var Collection<Character>
     *
     * @see _:characters
     */
    #[ApiProperty(description: 'List of characters who have been seen in the episode.')]
    #[Groups(['episode:read'])]
    #[ORM\ManyToMany(targetEntity: 'App\Entity\Character', mappedBy: 'episode')]
    private Collection $characters;

    /**
     * URL of the item.
     *
     * @see https://schema.org/url
     */
    #[ApiProperty(description: 'Link to the episode\'s own endpoint.', types: ['https://schema.org/url'])]
    #[Assert\Url]
    #[Groups(['episode:read', 'character:read'])]
    #[ORM\Column(type: 'text', nullable: true)]
    private string $url;

    /**
     * @see _:created
     */
    #[ApiProperty(description: 'The timestamp when the resource was created as a ISO 8601 timestamp (e.g., yyyy-MM-ddTHH:mm:ss.SSSZ).')]
    #[Groups('episode:read')]
    #[ORM\Column(type: 'datetime', nullable: true)]
    private ?\DateTimeInterface $created = null;

    public function __construct()
    {
        $this->characters = new ArrayCollection();
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

    public function setAirDate($airDate): void
    {
        $this->airDate = $airDate;
    }

    public function getAirDate(): string
    {
        return $this->airDate;
    }

    public function setEpisode($episode): void
    {
        $this->episode = $episode;
    }

    public function getEpisode(): string
    {
        return $this->episode;
    }

    public function addCharacter(Character $character): void
    {
        if (!$this->characters->contains($character)) {
            $this->characters[] = $character;
            $character->addEpisode($this);
        }
    }

    public function removeCharacter(Character $character): void
    {
        if ($this->characters->contains($character)) {
            $this->characters->removeElement($character);
            $character->removeEpisode($this);
        }
    }

    /**
     * @return Collection<Character>
     */
    public function getCharacters(): Collection
    {
        return $this->characters;
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
