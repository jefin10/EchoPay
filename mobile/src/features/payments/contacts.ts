import { Contact, ContactField, ContactsSortOrder, requestPermissionsAsync } from 'expo-contacts';

export interface DeviceContact {
  id: string;
  name: string;
  /** First phone number as stored on the device (unnormalised), or null. */
  phone: string | null;
}

export type ContactsResult = { granted: true; contacts: DeviceContact[] } | { granted: false; contacts: [] };

/** Ask for contacts permission and load name + first phone for every contact. */
export async function loadContacts(): Promise<ContactsResult> {
  const { granted } = await requestPermissionsAsync();
  if (!granted) return { granted: false, contacts: [] };
  const details = await Contact.getAllDetails([ContactField.FULL_NAME, ContactField.PHONES], {
    sortOrder: ContactsSortOrder.GivenName,
  });
  const contacts = details
    .map((d) => ({
      id: d.id,
      name: d.fullName?.trim() || d.phones?.[0]?.number || 'Unknown',
      phone: d.phones?.[0]?.number ?? null,
    }))
    .sort((a, b) => a.name.localeCompare(b.name));
  return { granted: true, contacts };
}

/** Case-insensitive name or number match. */
export function filterContacts(contacts: DeviceContact[], query: string): DeviceContact[] {
  const q = query.trim().toLowerCase();
  if (!q) return contacts;
  const digits = q.replace(/\D/g, '');
  return contacts.filter(
    (c) =>
      c.name.toLowerCase().includes(q) || (digits.length > 0 && (c.phone ?? '').replace(/\D/g, '').includes(digits)),
  );
}

/** Contacts whose name matches a spoken name: exact first, then prefix, then substring. */
export function matchContactsByName(contacts: DeviceContact[], spoken: string): DeviceContact[] {
  const q = spoken.trim().toLowerCase();
  if (!q) return [];
  const withPhone = contacts.filter((c) => c.phone);
  const exact = withPhone.filter((c) => c.name.toLowerCase() === q);
  if (exact.length) return exact;
  const prefix = withPhone.filter((c) => c.name.toLowerCase().split(/\s+/).some((w) => w.startsWith(q)));
  if (prefix.length) return prefix;
  return withPhone.filter((c) => c.name.toLowerCase().includes(q));
}
