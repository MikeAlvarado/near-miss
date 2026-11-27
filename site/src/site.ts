export const REPO = 'https://github.com/MikeAlvarado/near-miss'
export const ISSUES = `${REPO}/issues`
export const base = import.meta.env.BASE_URL
export const asset = (path: string) => `${base}${path}`

/** Where the "notify me" field sends emails: a Google Form.  */
export const WAITLIST = {
  action: 'https://docs.google.com/forms/d/e/1FAIpQLScUZaXmTQq0vCCnMhw-NWtUWJ1Wl7obejsR_1MypDnYHJp4GA/formResponse',
  field: 'entry.929266309',
  langField: 'entry.1632968214',
}
