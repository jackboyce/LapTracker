@extends('layouts.app')

@section('content')
<div class="container">
    <div class="row">
        <div class="col-md-10 col-md-offset-1">
            <div class="panel panel-default">
                <div class="panel-heading">Welcome</div>
                <div class="panel-body">
                    Your Application's Landing Page.
		    @if (Auth::guest())
                    	<head><meta http-equiv="refresh" content="0; url=/login" /></head>
		    @else
			<head><meta http-equiv="refresh" content="0; url=/home" /></head>
		    @endif
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
