import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { isSupabaseConfigured, supabase } from '../lib/supabase';
const AppContext = createContext(null);
const localKey = 'sivasakthi-cart-v1';
function readCart() { try { return JSON.parse(localStorage.getItem(localKey) || '[]'); } catch { return []; } }
export function AppProvider({ children }) {
  const [session, setSession] = useState(null); const [profile, setProfile] = useState(null); const [cart, setCart] = useState(readCart); const [wishlist, setWishlist] = useState([]); const [toast, setToast] = useState(''); const [authLoading, setAuthLoading] = useState(Boolean(isSupabaseConfigured));
  const notify = useCallback((message) => { setToast(message); window.clearTimeout(notify.timer); notify.timer = window.setTimeout(() => setToast(''), 3200); }, []);
  const loadProfile = useCallback(async (user) => { if (!user || !supabase) { setProfile(null); return; } const { data, error } = await supabase.from('profiles').select('*').eq('id', user.id).maybeSingle(); if (error) { notify(error.message); return; } setProfile(data); }, [notify]);
  const loadUserData = useCallback(async (user) => {
    if (!supabase || !user) { setWishlist([]); return; }
    const [{ data: cartData, error: cartError }, { data: wishData, error: wishError }] = await Promise.all([
      supabase.from('cart_items').select('product_id,quantity,products(id,name,price,discount_price,image_url,stock_quantity,active)').eq('user_id', user.id),
      supabase.from('wishlist_items').select('product_id').eq('user_id', user.id)
    ]);
    if (!cartError && cartData) setCart(cartData.filter(x => x.products?.active).map(x => ({ product: x.products, quantity: x.quantity })));
    if (wishError) notify(wishError.message); else setWishlist((wishData || []).map(x => x.product_id));
  }, [notify]);
  useEffect(() => {
    if (!supabase) { setAuthLoading(false); return; }
    supabase.auth.getSession().then(async ({ data }) => { setSession(data.session); if (data.session?.user) { await Promise.all([loadProfile(data.session.user), loadUserData(data.session.user)]); } setAuthLoading(false); });
    const { data: listener } = supabase.auth.onAuthStateChange((_event, next) => { setSession(next); setAuthLoading(false); if (next?.user) { window.setTimeout(() => { loadProfile(next.user); loadUserData(next.user); }, 0); } else { setProfile(null); setWishlist([]); setCart(readCart()); } });
    return () => listener.subscription.unsubscribe();
  }, [loadProfile, loadUserData]);
  useEffect(() => { if (!session) localStorage.setItem(localKey, JSON.stringify(cart)); }, [cart, session]);
  const addToCart = useCallback(async (product, quantity = 1) => {
    const count = Math.max(1, Math.min(99, Number(quantity) || 1));
    if (!session) { notify('Sign in to add products to your cart.'); window.location.assign('/login?next=/cart'); return; }
    setCart(current => {
      const found = current.find(x => x.product.id === product.id);
      return found ? current.map(x => x.product.id === product.id ? { ...x, quantity: Math.min(99, x.quantity + count) } : x) : [...current, { product, quantity: count }];
    });
    if (session && supabase) { const { error } = await supabase.from('cart_items').upsert({ user_id: session.user.id, product_id: product.id, quantity: Math.min(99, (cart.find(x => x.product.id === product.id)?.quantity || 0) + count) }, { onConflict: 'user_id,product_id' }); if (error) notify(error.message); }
    notify('Added to your cart');
  }, [cart, notify, session]);
  const setQuantity = useCallback(async (id, quantity) => { const next = Math.max(0, Math.min(99, Number(quantity) || 0)); setCart(current => next === 0 ? current.filter(x => x.product.id !== id) : current.map(x => x.product.id === id ? { ...x, quantity: next } : x)); if (session && supabase) { const result = next ? await supabase.from('cart_items').update({ quantity: next }).eq('user_id', session.user.id).eq('product_id', id) : await supabase.from('cart_items').delete().eq('user_id', session.user.id).eq('product_id', id); if (result.error) notify(result.error.message); } }, [notify, session]);
  const clearCart = useCallback(async () => { setCart([]); if (session && supabase) { const { error } = await supabase.from('cart_items').delete().eq('user_id', session.user.id); if (error) notify(error.message); } }, [notify, session]);
  const toggleWishlist = useCallback(async (id) => { if (!session) { notify('Sign in to save products to your wishlist.'); window.location.assign('/login?next=/wishlist'); return; } const exists = wishlist.includes(id); setWishlist(prev => exists ? prev.filter(x => x !== id) : [...prev, id]); if (session && supabase) { const result = exists ? await supabase.from('wishlist_items').delete().eq('user_id', session.user.id).eq('product_id', id) : await supabase.from('wishlist_items').insert({ user_id: session.user.id, product_id: id }); if (result.error) notify(result.error.message); } notify(exists ? 'Removed from wishlist' : 'Saved to wishlist'); }, [notify, session, wishlist]);
  const value = useMemo(() => ({ session, profile, setProfile, cart, wishlist, toast, notify, authLoading, addToCart, setQuantity, clearCart, toggleWishlist, isSupabaseConfigured, refreshUserData: () => session?.user && loadUserData(session.user), refreshProfile: () => session?.user && loadProfile(session.user) }), [session, profile, cart, wishlist, toast, notify, authLoading, addToCart, setQuantity, clearCart, toggleWishlist, loadUserData, loadProfile]);
  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}
export function useApp() { const value = useContext(AppContext); if (!value) throw new Error('useApp must be used inside AppProvider'); return value; }
