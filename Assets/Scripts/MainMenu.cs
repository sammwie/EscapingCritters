using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;

public class MainMenu : MonoBehaviour
{
    [Header("Title")]
    [SerializeField] private CanvasGroup titleGroup;
    [SerializeField] private CanvasGroup buttonsGroup;
    [SerializeField] private float titleFadeTime = 1f;
    [SerializeField] private float buttonsFadeTime = 0.5f;

    [Header("Scenes")]
    [SerializeField] private string characterCreatorScene = "CharacterCreator";

    private void Start()
    {
        titleGroup.alpha = 0f;
        buttonsGroup.alpha = 0f;
        buttonsGroup.interactable = false;
        buttonsGroup.blocksRaycasts = false;
        StartCoroutine(PlayIntro());
    }

    private IEnumerator PlayIntro()
    {
        yield return Fade(titleGroup, 0f, 1f, titleFadeTime);
        yield return Fade(buttonsGroup, 0f, 1f, buttonsFadeTime);
        buttonsGroup.interactable = true;
        buttonsGroup.blocksRaycasts = true;
    }

    private IEnumerator Fade(CanvasGroup group, float from, float to, float duration)
    {
        float t = 0f;
        while (t < duration)
        {
            t += Time.deltaTime;
            group.alpha = Mathf.Lerp(from, to, t / duration);
            yield return null;
        }
        group.alpha = to;
    }

    // Hook this to the Start button's OnClick.
    public void OnStartPressed()
    {
        // If a save already exists, this could branch to a Load option instead.
        SceneManager.LoadScene(characterCreatorScene);
    }

    // Hook this to a Quit button's OnClick.
    public void OnQuitPressed()
    {
        Application.Quit();
#if UNITY_EDITOR
        UnityEditor.EditorApplication.isPlaying = false;
#endif
    }
}
