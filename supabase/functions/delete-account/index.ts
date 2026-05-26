// @ts-nocheck

import { createClient } from 'npm:@supabase/supabase-js@2';

Deno.serve(async (req: Request) => {
  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const { user_id, avatar_url } = await req.json() as { user_id?: string; avatar_url?: string | null };
    if (!user_id) {
      return new Response(JSON.stringify({ error: 'Missing user_id' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
    const serviceRoleKey = Deno.env.get('SERVICE_ROLE_KEY') ?? '';

    if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey) {
      return new Response(JSON.stringify({ error: 'Missing Supabase environment variables' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: authData, error: authError } = await userClient.auth.getUser();
    if (authError || !authData.user || authData.user.id !== user_id) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const transactionRows = await adminClient.from('transactions').select('image_path').eq('user_id', user_id);

    const avatarPaths: string[] = [];
    if (avatar_url && typeof avatar_url === 'string') {
      const avatarMarker = '/avatars/';
      const avatarIndex = avatar_url.indexOf(avatarMarker);
      if (avatarIndex !== -1) {
        avatarPaths.push(decodeURIComponent(avatar_url.substring(avatarIndex + avatarMarker.length).split('?')[0]));
      }
    }

    const receiptPaths: string[] = [];
    for (const row of transactionRows.data ?? []) {
      const imageUrl = row.image_path?.toString();
      if (!imageUrl) continue;
      const receiptMarker = '/receipts/';
      const receiptIndex = imageUrl.indexOf(receiptMarker);
      if (receiptIndex !== -1) {
        receiptPaths.push(decodeURIComponent(imageUrl.substring(receiptIndex + receiptMarker.length).split('?')[0]));
      }
    }

    if (receiptPaths.length > 0) {
      await adminClient.storage.from('receipts').remove(receiptPaths);
    }

    if (avatarPaths.length > 0) {
      await adminClient.storage.from('avatars').remove(avatarPaths);
    }

    await adminClient.from('transactions').delete().eq('user_id', user_id);
    await adminClient.from('budgets').delete().eq('user_id', user_id);
    await adminClient.from('wallets').delete().eq('user_id', user_id);

    const { error: deleteError } = await adminClient.auth.admin.deleteUser(user_id);
    if (deleteError) {
      return new Response(JSON.stringify({ error: deleteError.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});