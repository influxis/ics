<?php
  require_once("lccs.php");
  $title = "LCCS External Authentication Sample";

  #
  # Enter your authentication details below:
  #
  $account = "sdkaccount";
  $room    = "sdkroom";
  $devuser = "sdkuser";
  $devpass = "sdkpassword";
  $secret  = "sdkaccountsharedsecret";
  
  $host  = "http://connectnow.acrobat.com";
  $accountURL = "{$host}/{$account}";
  $roomURL = "{$accountURL}/{$room}";

  session_start();

  if (isset($_REQUEST["user"])) {
    $user = $_REQUEST["user"];
    $role = (int) $_REQUEST["role"];

    if (isset($_SESSION["XSESSION"])) {
      $session = $_SESSION["XSESSION"];
    } else {
      $am = new RTCAccount($accountURL);
      $am->login($devuser, $devpass);
      $session = $am->getSession($room);
    
      $_SESSION["XSESSION"] = $session;
    }

    $token = $session->getAuthenticationToken($secret, $user, $user, $role);
  } else {
    $user = "bob";
    $role = 100;
  }

  function select($r) {
    global $role;
    return ($role == $r) ? "selected" : "";
  }
?>

<html>
  <head>
    <title><?= $title ?></title>
    <script type="text/javascript">
      function loaded() {
	<?php
	  if (isset($token)) {
        ?>
            win = window.open(
              'Flexternal.html?roomURL=<?php echo urlencode($roomURL) ?>&authToken=<?php echo urlencode($token) ?>',
              '_blank',
              'left=20,top=20,width=800,height=600,toolbar=1,resizable=1');
        <?php
	  }
        ?>
      }
    </script>
  </head>
  <body onload="loaded()">
    <h2><?php echo $title ?></h2>
    <h4>Connecting to room <?php echo $roomURL ?></h4>
    <form method="POST">
      <b>User Name</b>
      <input type="text" name="user" value='<?php echo $user ?>'>
      <b>User Role</b>
      <select name="role">
	<option value="100" <?php echo select(100) ?>>100 - Owner</option>
	<option value="50" <?php echo select(50) ?>>50 - Publisher</option>
	<option value="5" <?php echo select(5) ?>>5 - Guest</option>
	<option value="0" <?php echo select(0) ?>>0 - None</option>
      </select>
      <input type="submit" value="Enter Room"></td>
    </form>
  </body>
</html>
