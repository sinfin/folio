window.Folio.Stimulus.register('f-devise-invitations-new', class extends window.Stimulus.Controller {
  static targets = ['form', 'submitButton', 'ageAgreement', 'termsAgreement']

  static outlets = ['f-devise-omniauth-forms', 'f-devise-omniauth']

  static values = {
    loading: Boolean
  }

  connect() {
    this.checkAgreements()
  }

  checkAgreements() {
    const ageChecked = this.hasAgeAgreementTarget ? this.ageAgreementTarget.checked : true
    const termsChecked = this.hasTermsAgreementTarget ? this.termsAgreementTarget.checked : true
    const allChecked = ageChecked && termsChecked

    // Disable/enable submit button
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = !allChecked
    }

    // Disable/enable hidden omniauth form buttons via outlet
    this.fDeviseOmniauthFormsOutlets.forEach(outlet => {
      outlet.setDisabled(!allChecked)
    })

    // Disable/enable visible omniauth buttons via outlet
    this.fDeviseOmniauthOutlets.forEach(outlet => {
      outlet.setDisabled(!allChecked)
    })
  }

  onAgreementChange() {
    this.checkAgreements()
  }
})
