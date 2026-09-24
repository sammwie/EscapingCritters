using UnityEngine;

public class CharacterAppearance : MonoBehaviour
{
    [Header("Layers")]
    [SerializeField] private SpriteRenderer body;
    [SerializeField] private SpriteRenderer hair;
    [SerializeField] private SpriteRenderer outfit;

    [Header("Options")]
    public Sprite[] hairStyles;
    public Color[] skinTones;
    public Color[] hairColors;
    public Color[] outfitColors;

    [Header("Behavior")]
    [SerializeField] private bool applyProfileOnStart = true;

    private void Start()
    {
        if (applyProfileOnStart) Apply(PlayerProfile.Current);
    }

    public void Apply(PlayerProfile profile)
    {
        if (body != null && skinTones.Length > 0)
            body.color = skinTones[Wrap(profile.skinIndex, skinTones.Length)];

        if (hair != null)
        {
            if (hairStyles.Length > 0)
                hair.sprite = hairStyles[Wrap(profile.hairStyle, hairStyles.Length)];
            if (hairColors.Length > 0)
                hair.color = hairColors[Wrap(profile.hairColorIndex, hairColors.Length)];
        }

        if (outfit != null && outfitColors.Length > 0)
            outfit.color = outfitColors[Wrap(profile.outfitColorIndex, outfitColors.Length)];
    }

    private static int Wrap(int value, int length)
    {
        return ((value % length) + length) % length;
    }
}
