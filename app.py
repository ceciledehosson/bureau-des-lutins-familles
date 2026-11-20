"""Bureau des Lutins — prototype Streamlit multi-familles."""
import streamlit as st
from supabase import create_client

st.set_page_config(page_title="Le Bureau des Lutins", page_icon="🎄", layout="centered")
st.markdown("""<style>
/* Palette claire homogène : le thème Streamlit fournit les couleurs de texte. */
.stApp {background-color:#fffaf3}
h1, h2, h3 {color:#245340!important}
[data-testid="stSidebar"] {background-color:#e8eee7}
[data-testid="stSidebar"] h1,
[data-testid="stSidebar"] h2,
[data-testid="stSidebar"] h3 {color:#245340!important}

/* Onglets : blanc/gris clair + typographie foncée lisible. */
.stTabs [data-baseweb="tab-list"] {background:#e6ebe5!important;border-radius:9px;padding:5px;gap:4px}
.stTabs button[data-baseweb="tab"] {background:#eef2ed!important;border-radius:7px;color:#213b30!important}
.stTabs button[data-baseweb="tab"] p,
.stTabs button[data-baseweb="tab"] span {color:#213b30!important;opacity:1!important}
.stTabs button[data-baseweb="tab"][aria-selected="true"] {background:#245340!important}
.stTabs button[data-baseweb="tab"][aria-selected="true"] p,
.stTabs button[data-baseweb="tab"][aria-selected="true"] span {color:#fff!important}
.stTabs [data-baseweb="tab-highlight"] {background:#a92335!important}

/* Formulaires : noms de champs visibles et saisie toujours lisible. */
[data-testid="stWidgetLabel"] p {color:#213b30!important;opacity:1!important}
[data-testid="stForm"] {border:1px solid #87978c!important}
[data-baseweb="input"] input,
[data-baseweb="textarea"] textarea {background-color:#fff!important;color:#203a30!important}
[data-baseweb="input"] input::placeholder,
[data-baseweb="textarea"] textarea::placeholder {color:#5c6d63!important;opacity:1!important}
[data-baseweb="select"] > div {background:#fff!important;color:#203a30!important}
[data-baseweb="select"] > div * {color:#203a30!important}
.stButton button[kind="primary"],
[data-testid="stFormSubmitButton"] button[kind="primary"] {background:#a92335!important;border-color:#a92335!important;color:#fff!important}
.stButton button[kind="primary"] *,
[data-testid="stFormSubmitButton"] button[kind="primary"] * {color:#fff!important}
.stButton button[kind="secondary"] {background:#52675c!important;color:#fff!important;border-color:#52675c!important}
.stButton button[kind="secondary"] * {color:#fff!important}
[data-testid="stExpander"] summary {background:#e6ebe5!important;color:#203a30!important}
[data-testid="stExpander"] summary * {color:#203a30!important}
</style>""", unsafe_allow_html=True)

@st.cache_resource
def db():
    return create_client(st.secrets["SUPABASE_URL"], st.secrets["SUPABASE_ANON_KEY"])

def rpc(name, **params):
    return db().rpc(name, params).execute().data

def refresh():
    st.session_state.board = rpc("board", p_code=st.session_state.code)

def operation(name, **params):
    try:
        rpc(name, p_code=st.session_state.code, **params)
        refresh()
        st.rerun()
    except Exception as err:
        st.error(f"Le serveur des lutins proteste : {err}")

def enter(code):
    code = code.strip()
    if not code:
        st.error("Le code ne peut pas être vide.")
        return
    try:
        board = rpc("board", p_code=code)
        if not board:
            st.error("Code inconnu du Père Noël !")
        else:
            st.session_state.code = code
            st.session_state.board = board
            st.rerun()
    except Exception as err:
        st.error(f"Impossible de joindre l'atelier : {err}")

st.title("🎄 Le Bureau des Lutins")
st.caption("Les cadeaux s'organisent. Les surprises restent ! 🤫")
st.caption("📂 Dépôt GitHub : ceciledehosson/bureau-des-lutins-familles")
st.caption("© 2026 Cécile de Hosson — Tous droits réservés.")

if "code" not in st.session_state:
    access, new_family, join = st.tabs(["🧝 Entrer", "🎄 Créer un Bureau", "✉️ Rejoindre"])
    with access:
        with st.form("login"):
            code = st.text_input("Mon code secret", type="password")
            submit = st.form_submit_button("Ouvrir ma hotte", type="primary")
        if submit:
            enter(code)
    with new_family:
        st.write("Un espace privé pour votre famille, gratuit et réservé à Noël.")
        with st.form("new_family"):
            title = st.text_input("Nom du Bureau familial", placeholder="Les lutins de la famille Martin", max_chars=80)
            name = st.text_input("Ton prénom (créateur ou créatrice du Bureau)", placeholder="Ex. : Cécile", max_chars=60)
            create = st.form_submit_button("Créer notre Bureau 🎅")
        if create:
            try:
                result = rpc("create_family", p_title=title.strip(), p_name=name.strip())
                st.session_state.new_codes = result
            except Exception as err:
                st.error(f"Impossible de créer le Bureau : {err}")
        if "new_codes" in st.session_state:
            st.success("Ton Bureau est créé ! Copie ces deux codes maintenant.")
            st.code(st.session_state.new_codes["code"], language=None)
            st.caption("Ton code personnel : à conserver soigneusement.")
            st.code(st.session_state.new_codes["invitation"], language=None)
            st.caption("Code d'invitation : à transmettre uniquement à ta famille.")
            if st.button("Entrer dans mon nouveau Bureau"):
                code = st.session_state.new_codes["code"]
                del st.session_state.new_codes
                enter(code)
    with join:
        with st.form("join_family"):
            invitation = st.text_input("Code d'invitation reçu", type="password")
            nickname = st.text_input("Ton prénom (pour que les autres lutins te reconnaissent)", placeholder="Ex. : Emmanuelle", max_chars=60)
            do_join = st.form_submit_button("Rejoindre ma famille")
        if do_join:
            try:
                st.session_state.joined_code = rpc("join_family", p_invitation=invitation.strip(), p_name=nickname.strip())["code"]
            except Exception as err:
                st.error(f"Impossible de rejoindre le Bureau : {err}")
        if "joined_code" in st.session_state:
            st.success("Bienvenue parmi les lutins ! Conserve ton code personnel.")
            st.code(st.session_state.joined_code, language=None)
            if st.button("Accéder à ma lettre"):
                code = st.session_state.joined_code
                del st.session_state.joined_code
                enter(code)
    st.caption("Ne partage jamais ton code personnel : il donne accès à ton identité de lutin.")
    st.stop()

if "board" not in st.session_state:
    refresh()
board = st.session_state.board
if not board:
    st.session_state.clear()
    st.error("Ce code n'est plus valide. Recharge la page.")
    st.stop()
me = board["me"]
people = {m["id"]: m["name"] for m in board["members"]}

with st.sidebar:
    st.header(f"🧝 {people[me]}")
    st.write(f"🎄 {board['family']}")
    if st.button("🔄 Actualiser", use_container_width=True):
        refresh()
        st.rerun()
    if st.button("🚪 Se déconnecter", use_container_width=True):
        st.session_state.clear()
        st.rerun()
    st.caption("Les réservations sur ta propre liste restent secrètes.")

priorities = ["Ça me ferait plaisir", "J’en rêve", "Si le Père Noël est riche"]
letter, workshop, sleigh = st.tabs(["💌 Ma lettre", "🎁 L'atelier", "🛷 Ma hotte"])

with letter:
    st.subheader("Ma lettre au Père Noël")
    with st.expander("➕ Ajouter une envie"):
        with st.form("wish_new", clear_on_submit=True):
            title = st.text_input("Cadeau", max_chars=180)
            details = st.text_area("Précisions", max_chars=1500)
            price = st.number_input("Prix indicatif (€)", min_value=0.0, step=1.0)
            unknown = st.checkbox("Prix inconnu")
            url = st.text_input("Lien éventuel", max_chars=1000)
            priority = st.selectbox("Priorité", priorities)
            save = st.form_submit_button("Envoyer au Père Noël 🎅", type="primary")
        if save:
            if not title.strip() or (url and not url.startswith(("https://", "http://"))):
                st.warning("Indique le cadeau et une adresse valide si tu ajoutes un lien.")
            else:
                operation("save_wish", p_id=None, p_title=title.strip(), p_details=details,
                          p_price=None if unknown else price, p_url=url, p_priority=priority)
    mine = [w for w in board["wishes"] if w["owner_id"] == me]
    if not mine:
        st.info("Ta lettre est encore vide !")
    for w in mine:
        with st.expander("🎄 " + w["title"]):
            st.caption("Chut : aucune information sur les réservations !")
            with st.form("edit_" + w["id"]):
                t = st.text_input("Cadeau", value=w["title"])
                d = st.text_area("Précisions", value=w["details"])
                p = st.number_input("Prix (€)", min_value=0.0, value=float(w["price"] or 0), key="p"+w["id"])
                unk = st.checkbox("Prix inconnu", value=w["price"] is None, key="u"+w["id"])
                link = st.text_input("Lien", value=w["url"])
                pri = st.selectbox("Priorité", priorities, index=priorities.index(w["priority"]))
                changed = st.form_submit_button("Enregistrer")
            if changed:
                if not t.strip() or (link and not link.startswith(("https://", "http://"))):
                    st.warning("Titre ou lien incorrect.")
                else:
                    operation("save_wish", p_id=w["id"], p_title=t.strip(), p_details=d,
                              p_price=None if unk else p, p_url=link, p_priority=pri)
            if st.button("🗑️ Supprimer", key="del"+w["id"]):
                operation("delete_wish", p_id=w["id"])

with workshop:
    st.subheader("L'atelier des lutins")
    others = [m for m in board["members"] if m["id"] != me]
    if not others:
        st.info("Envoie le code d'invitation aux autres lutins pour commencer !")
    else:
        person = st.selectbox("À qui veux-tu faire plaisir ?", [m["name"] for m in others])
        owner = next(m["id"] for m in others if m["name"] == person)
        gifts = [w for w in board["wishes"] if w["owner_id"] == owner]
        if not gifts:
            st.info("Ce lutin n'a pas encore envoyé sa lettre.")
        for w in gifts:
            r = w["reservation"]
            with st.container(border=True):
                st.markdown("#### 🎁 " + w["title"])
                if w["details"]:
                    st.write(w["details"])
                st.caption(w["priority"] + " · " + (str(w["price"]) + " €" if w["price"] is not None else "Prix inconnu"))
                if w["url"].startswith(("https://", "http://")):
                    st.link_button("🔗 Voir le cadeau", w["url"])
                if not r:
                    if st.button("Je m'en occupe ! 🎅", key="reserve"+w["id"], type="primary"):
                        operation("reserve_wish", p_wish_id=w["id"], p_action="reserve")
                else:
                    coordinator = r["organizer_id"]
                    participants = r["participants"]
                    my_part = next((p for p in participants if p["member_id"] == me), None)
                    st.info(f"Coordonné par {people[coordinator]} · {r['status']}")
                    if coordinator == me:
                        a,b = st.columns(2)
                        if r["status"] != "Acheté" and a.button("✅ Acheté", key="buy"+w["id"]):
                            operation("reserve_wish", p_wish_id=w["id"], p_action="buy")
                        if b.button("↩️ Libérer", key="free"+w["id"], disabled=bool(participants)):
                            operation("reserve_wish", p_wish_id=w["id"], p_action="release")
                    for p in participants:
                        st.write(f"🤝 {people[p['member_id']]}" + (f" · {p['amount']} €" if p["amount"] is not None else " · montant à convenir"))
                    if coordinator != me:
                        with st.form("contribute"+w["id"]):
                            st.write("🤝 " + ("Modifier ma participation" if my_part else "Participer à ce cadeau"))
                            exact = st.checkbox("Préciser mon montant", value=bool(my_part and my_part["amount"] is not None))
                            amount = st.number_input("Contribution (€)", min_value=1.0,
                                value=float(my_part["amount"]) if my_part and my_part["amount"] is not None else 10.0,
                                disabled=not exact, key="amount"+w["id"])
                            add = st.form_submit_button("Confirmer ma participation")
                        if add:
                            operation("contribute", p_wish_id=w["id"], p_action="join",
                                      p_amount=amount if exact else None)
                        if my_part and st.button("Retirer ma participation", key="leave"+w["id"]):
                            operation("contribute", p_wish_id=w["id"], p_action="leave", p_amount=None)

with sleigh:
    st.subheader("Ma hotte 🛷")
    any_gift = False
    for w in board["wishes"]:
        r = w["reservation"]
        if not r:
            continue
        if r["organizer_id"] == me:
            st.write(f"🎁 **{w['title']}** pour **{people[w['owner_id']]}** · {r['status']}")
            any_gift = True
        for p in r["participants"]:
            if p["member_id"] == me:
                st.write(f"🤝 **{w['title']}** pour **{people[w['owner_id']]}** · contribution " +
                         (f"{p['amount']} €" if p["amount"] is not None else "à convenir"))
                any_gift = True
    if not any_gift:
        st.info("La hotte est encore vide !")

st.divider()
st.caption("❄️ Le Bureau des Lutins · Gratuit, sans publicité, juste pour Noël 🎄")
