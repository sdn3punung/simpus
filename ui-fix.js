// Small compatibility layer so the visual refresh can be deployed without replacing app.js.
const navIcons={
  dashboard:'<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>',
  catalog:'<path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H20v16H6.5A2.5 2.5 0 0 0 4 21z"/><path d="M4 5.5v15A2.5 2.5 0 0 1 6.5 18H20M8 7h8M8 10h7"/>',
  members:'<path d="M16 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="10" cy="7" r="4"/><path d="M20 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>',
  copies:'<rect x="3" y="4" width="18" height="4" rx="1"/><path d="M5 8v12h14V8M10 12h4"/>',
  loans:'<path d="m17 2 4 4-4 4M3 11V9a3 3 0 0 1 3-3h15M7 22l-4-4 4-4M21 13v2a3 3 0 0 1-3 3H3"/>',
  visits:'<path d="M22 12h-4l-3 9L9 3l-3 9H2"/>',
  imports:'<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M17 8l-5-5-5 5M12 3v12"/>',
  reports:'<path d="M3 3v18h18"/><path d="m19 9-5 5-4-4-5 5"/>',
  audit:'<path d="M3 12a9 9 0 1 0 2.64-6.36L3 8"/><path d="M3 3v5h5M12 7v5l4 2"/>'
};
function refreshMenuIcons(){
  document.querySelectorAll('#nav .nav-link').forEach(button=>{
    const slot=button.querySelector('span');
    if(!slot)return;
    if(slot.dataset.icon===button.dataset.page&&slot.querySelector('svg'))return;
    slot.classList.add('nav-icon');
    slot.dataset.icon=button.dataset.page;
    slot.innerHTML=`<svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">${navIcons[button.dataset.page]||navIcons.dashboard}</svg>`;
  });
}
const nav=document.getElementById('nav');
if(nav){new MutationObserver(refreshMenuIcons).observe(nav,{childList:true,subtree:true});refreshMenuIcons()}
// Capture the close/cancel clicks before the browser validates required form fields.
document.addEventListener('click',event=>{
  const button=event.target.closest('#modal .modal-head button, #modal .modal-actions .secondary');
  if(!button)return;
  event.preventDefault();
  const dialog=document.getElementById('modal');
  if(dialog?.open)dialog.close();
},true);
