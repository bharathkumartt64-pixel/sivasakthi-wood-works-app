import { Link } from 'react-router-dom';
import { Settings2 } from 'lucide-react';
import { useApp } from '../state/AppContext';
export default function ConfigNotice(){const {isSupabaseConfigured}=useApp(); return !isSupabaseConfigured?<div className="config-notice"><Settings2 size={17}/><span>Connect a Supabase project to enable live products, accounts and ordering.</span><Link to="/about">Setup details</Link></div>:null;}
