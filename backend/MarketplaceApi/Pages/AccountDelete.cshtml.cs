using System.ComponentModel.DataAnnotations;
using MarketplaceApi.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace MarketplaceApi.Pages;

public class AccountDeleteModel : PageModel
{
    private readonly IAccountDeletionService _accountDeletionService;

    public AccountDeleteModel(IAccountDeletionService accountDeletionService)
    {
        _accountDeletionService = accountDeletionService;
    }

    [BindProperty]
    public InputModel Input { get; set; } = new();

    public string? StatusMessage { get; private set; }
    public bool IsSuccess { get; private set; }

    public void OnGet()
    {
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid)
        {
            StatusMessage = "Veuillez fournir un email ou un numéro de téléphone valide.";
            IsSuccess = false;
            return Page();
        }

        var result = await _accountDeletionService.RequestDeletionAsync(Input.Identifier, Input.Identifier);

        if (result == AccountDeletionResult.Success)
        {
            StatusMessage = "Votre demande de suppression a bien été enregistrée. Nous traiterons votre demande dans les meilleurs délais.";
            IsSuccess = true;
            Input = new InputModel();
            return Page();
        }

        if (result == AccountDeletionResult.AlreadyDeleted)
        {
            StatusMessage = "Ce compte a déjà été supprimé ou sa suppression a déjà été traitée.";
            IsSuccess = false;
            return Page();
        }

        StatusMessage = "Aucun compte correspondant n'a été trouvé. Vérifiez l'email ou le numéro de téléphone saisi.";
        IsSuccess = false;
        return Page();
    }

    public class InputModel
    {
        [Required(ErrorMessage = "Veuillez saisir un email ou un numéro de téléphone.")]
        [Display(Name = "Email ou numéro de téléphone")]
        public string? Identifier { get; set; }
    }
}
