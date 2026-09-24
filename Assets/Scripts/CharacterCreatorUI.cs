using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;

public class CharacterCreatorUI : MonoBehaviour
{
    [SerializeField] private TMP_InputField nameInput;
    [SerializeField] private TMP_Text errorText;
    [SerializeField] private CharacterAppearance preview;
    [SerializeField] private string gameSceneName = "Game";
    [SerializeField] private int maxNameLength = 12;

    private PlayerProfile profile;

    private void Start()
    {
        profile = PlayerProfile.Current;
        nameInput.characterLimit = maxNameLength;
        nameInput.text = profile.playerName;
        if (errorText != null) errorText.text = "";
        preview.Apply(profile);
    }

    // Hook these to the arrow buttons. Pass 1 for next and -1 for previous.
    public void CycleHairStyle(int dir) { profile.hairStyle += dir; Refresh(); }
    public void CycleSkin(int dir) { profile.skinIndex += dir; Refresh(); }
    public void CycleHairColor(int dir) { profile.hairColorIndex += dir; Refresh(); }
    public void CycleOutfitColor(int dir) { profile.outfitColorIndex += dir; Refresh(); }

    public void OnStartPressed()
    {
        string chosen = nameInput.text.Trim();
        if (string.IsNullOrEmpty(chosen))
        {
            if (errorText != null) errorText.text = "Please enter a name.";
            return;
        }

        profile.playerName = chosen;
        PlayerProfile.Save();
        SceneManager.LoadScene(gameSceneName);
    }

    private void Refresh()
    {
        preview.Apply(profile);
    }
}
