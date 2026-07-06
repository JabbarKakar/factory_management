import { initializeApp } from 'firebase-admin/app';

initializeApp();

export { createFactoryAndOwner } from './callables/createFactoryAndOwner';
export { sendTeamInvite } from './callables/sendTeamInvite';
export { acceptTeamInvite } from './callables/acceptTeamInvite';
export { revokeTeamInvite } from './callables/revokeTeamInvite';
